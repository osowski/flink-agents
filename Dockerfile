# Stage 1: Build all Java artifacts
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY . .
# Build examples + dist modules only; compile examples against Flink 2.1.1
RUN mvn clean package -DskipTests -B -Dflink.version=2.1.1 -pl examples,dist/common,dist/flink-2.1 -am

# Rename JARs to stable, version-independent names for predictable jarURI
RUN mv dist/common/target/flink-agents-dist-common-*.jar \
        /tmp/flink-agents-dist-common.jar && \
    mv dist/flink-2.1/target/flink-agents-dist-flink-2.1-*-thin.jar \
        /tmp/flink-agents-dist-flink-2.1-thin.jar && \
    mv examples/target/flink-agents-examples-*.jar \
        /tmp/flink-agents-examples.jar

# Stage 2: Final Flink image with agent JARs installed
FROM confluentinc/cp-flink:2.1.1-cp2-java21
COPY --from=builder /tmp/flink-agents-dist-common.jar         $FLINK_HOME/usrlib/
COPY --from=builder /tmp/flink-agents-dist-flink-2.1-thin.jar $FLINK_HOME/usrlib/
COPY --from=builder /tmp/flink-agents-examples.jar            $FLINK_HOME/usrlib/
