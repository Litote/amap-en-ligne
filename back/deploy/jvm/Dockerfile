# Runtime image of the JVM deployment (Ktor CIO + Postgres + GoTrue).
#
# Prerequisite: `cd back && ./gradlew :deploy:jvm:installDist` (the image only packages build/install/jvm).
#
# Stage 1 builds a trimmed Java 25 runtime with jlink (the code is compiled for JVM 25). The module list
# comes from jdeps; regenerate it after adding/upgrading a runtime dependency:
#   cd back/deploy/jvm/build/install/jvm/lib && \
#     jdeps --ignore-missing-deps --print-module-deps --multi-release 25 --class-path '*' *.jar
FROM eclipse-temurin:25-jdk-alpine AS jre-build
RUN jlink \
      --add-modules java.base,java.compiler,java.desktop,java.instrument,java.management,java.naming,java.net.http,java.security.jgss,java.security.sasl,java.sql,jdk.unsupported \
      --strip-debug \
      --no-header-files \
      --no-man-pages \
      --compress=zip-6 \
      --output /jre

FROM alpine:3.22
ENV JAVA_HOME=/opt/java
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-build /jre ${JAVA_HOME}
RUN addgroup -S amap && adduser -S -G amap amap
WORKDIR /app
COPY build/install/jvm/ .
USER amap
EXPOSE 8080
ENTRYPOINT ["bin/jvm"]
