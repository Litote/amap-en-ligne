# Runtime image of the JVM deployment (Ktor CIO + Postgres + GoTrue).
#
# Prerequisite: `cd back && ./gradlew :deploy:jvm:installDist` (the image only packages build/install/jvm).
#
# Stage 1 builds a trimmed Java 25 runtime with jlink (the code is compiled for JVM 25). The module list
# comes from jdeps; regenerate it after adding/upgrading a runtime dependency:
#   cd back/deploy/jvm/build/install/jvm/lib && \
#     jdeps --ignore-missing-deps --print-module-deps --multi-release 25 --class-path '*' *.jar
FROM eclipse-temurin:25-jdk-alpine@sha256:22edbb1021420ae6e248519d1af07577742314d67d4c60fcbb2e285b7e47fa78 AS jre-build
RUN jlink \
      --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management,java.naming,java.net.http,java.security.jgss,java.security.sasl,java.sql,jdk.unsupported \
      --strip-debug \
      --no-header-files \
      --no-man-pages \
      --compress=zip-6 \
      --output /jre

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
ENV JAVA_HOME=/opt/java
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-build /jre ${JAVA_HOME}
RUN addgroup -S amap && adduser -S -G amap amap
WORKDIR /app
COPY build/install/jvm/ .
USER amap
EXPOSE 8080
ENTRYPOINT ["bin/jvm"]
