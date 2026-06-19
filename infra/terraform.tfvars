aws_region     = "eu-west-3"
zip_path       = "../back/deploy/lambda/build/libs/lambda.zip"
koin_log_level = "INFO"
# Lambda CPU scales with memory: 1024 MB (~0.58 vCPU) speeds up the GraalVM native
# INIT (DataLambda cold start). Power-tune (512 / 1024 / 1769) against observed
# INIT_DURATION and cost. Only affects the DataLambda (the email lambda keeps 256).
lambda_memory_mb       = 1024
lambda_timeout_seconds = 30
log_retention_days     = 14
throttling_burst_limit = 100
throttling_rate_limit  = 50
# CORS disabled: same-origin prod deployment (the web app is served under the same domain as the API).
# Set ["*"] for permissive dev, or an explicit list of URLs for a whitelist (federation).
cors_allow_origins = []
# cognito_callback_urls, cognito_logout_urls, instance_api_url, ses_from_email → secrets.auto.tfvars (not committed)
# jwt_issuer_url and jwt_audience are passed via TF_VAR_* (not committed)
