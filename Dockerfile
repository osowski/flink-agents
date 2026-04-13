# Stage 1: Build all Java artifacts
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY . .
# Build examples + dist modules only; compile examples against Flink 2.1.1
RUN mvn clean package -DskipTests -B -Dflink.version=2.1.1 -pl examples,dist/common,dist/flink-2.1 -am

# Rename JARs to stable, version-independent names for predictable jarURI.
# -v logs the actual matched filename for glob-match verification in CI.
RUN mv -v dist/common/target/flink-agents-dist-common-*.jar \
          /tmp/flink-agents-dist-common.jar && \
    mv -v dist/flink-2.1/target/flink-agents-dist-flink-2.1-*-thin.jar \
          /tmp/flink-agents-dist-flink-2.1-thin.jar && \
    mv -v examples/target/flink-agents-examples-*.jar \
          /tmp/flink-agents-examples.jar

# flink-connector-files is a dependency of the examples JAR but is not bundled
# in the confluentinc/cp-flink base image. Copy it from the Maven cache so the
# classloader can find StreamFormat and related types at runtime.
RUN find /root/.m2/repository/org/apache/flink/flink-connector-files \
         -name "flink-connector-files-*.jar" \
         ! -name "*-sources.jar" ! -name "*-tests.jar" ! -name "*-javadoc.jar" \
    | sort | tail -1 | xargs -I{} mv -v {} /tmp/flink-connector-files.jar

# Stage 2: Final Flink image with agent JARs installed
# /opt/flink is $FLINK_HOME as defined in confluentinc/cp-flink base image
FROM confluentinc/cp-flink:2.1.1-cp2-java21
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.revision=$GIT_SHA \
      org.opencontainers.image.source="https://github.com/osowski/flink-agents"
COPY --from=builder /tmp/flink-agents-dist-common.jar         /opt/flink/usrlib/
COPY --from=builder /tmp/flink-agents-dist-flink-2.1-thin.jar /opt/flink/usrlib/
COPY --from=builder /tmp/flink-agents-examples.jar            /opt/flink/usrlib/
COPY --from=builder /tmp/flink-connector-files.jar            /opt/flink/usrlib/
# Install input data at a fixed path present on every pod (JobManager and TaskManager).
# copyResource() extracts to /tmp/ on the JobManager only — unusable by TaskManagers
# in Kubernetes because they run in separate pods with isolated filesystems.
COPY --from=builder /build/examples/src/main/resources/input_data.txt /opt/flink/usrlib/input_data.txt
