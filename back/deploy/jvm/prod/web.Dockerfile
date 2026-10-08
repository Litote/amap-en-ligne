# Web image of the self-hosted JVM deployment: the Flutter web build served by nginx, which
# also reverse-proxies the api and GoTrue containers (see nginx.conf).
#
# Build context = the Flutter web build; the nginx conf comes from the named `conf` context:
#   cd front && flutter build web --wasm
#   docker buildx build -f back/deploy/jvm/prod/web.Dockerfile \
#     --build-context conf=back/deploy/jvm/prod -t amap-en-ligne-web front/build/web
FROM nginx:1.29-alpine
COPY --from=conf nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html
