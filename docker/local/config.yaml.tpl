skip_config_update: ${SKIP_CONFIG_UPDATE}
drop_tasks_db: ${DROP_TASKS_DB}
databases:
  - auth-db
  - my-db
  - tasks
  - herald
  - katara
  - slacker
  - jira-bus
etcd:
  public_ip: "${PUBLIC_IP}"
  company_name: "${COMPANY_NAME}"
  product_name: "${PRODUCT_NAME}"
  encryption_key: "${OPTSCALE_KEY}"
  release: "${RELEASE}"
  katara_scheduler_timeout: "${KATARA_SCHEDULER_TIMEOUT}"
  bumi_scheduler_timeout: "${BUMI_SCHEDULER_TIMEOUT}"
  bumi_worker:
    max_retries: "${BUMI_WORKER_MAX_RETRIES}"
    wait_timeout: "${BUMI_WORKER_WAIT_TIMEOUT}"
    task_timeout: "${BUMI_WORKER_TASK_TIMEOUT}"
    run_period: "${BUMI_WORKER_RUN_PERIOD}"
  optscale_service_emails:
    recipient: ""
    enabled: "False"
  optscale_error_emails:
    recipient: ""
    enabled: "False"
  skip_email_filters: {}
  google_calendar_service:
    enabled: "False"
    access_key:
      type: ""
      project_id: ""
      private_key_id: ""
      private_key: ""
      client_email: ""
      client_id: ""
      auth_uri: ""
      token_uri: ""
      auth_provider_x509_cert_url: ""
      client_x509_cert_url: ""
  domains_blacklists:
    new_employee_email: []
    registration: []
    failed_import_email: []
  domains_whitelists:
    new_employee_email: []
    registration: []
    failed_import_email: []
  secret:
    cluster: "${CLUSTER_SECRET}"
    agent: "${AGENT_SECRET}"
  images_source:
    host: "local"
    tag: "${RELEASE}"
  restapi:
    invite_expiration_days: "${INVITE_EXPIRATION_DAYS}"
    host: "restapi"
    port: "8999"
    demo:
      multiplier: "${DEMO_MULTIPLIER}"
    report_imports:
      not_processed_threshold_secs: "${IMPORT_REPORTS_NOT_PROCESSED_THRESHOLD_SECS}"
      message_expiration_secs: "${IMPORT_REPORTS_MESSAGE_EXPIRATION_SECS}"
  auth:
    host: "auth"
    port: "8905"
  katara:
    host: "katara"
    port: "${KATARA_PORT}"
  authdb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "auth-db"
  heralddb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "herald"
  restdb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "my-db"
    port: "${MARIADB_PORT}"
  kataradb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "katara"
  slackerdb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "slacker"
    port: "${MARIADB_PORT}"
  jirabusdb:
    host: "mariadb"
    user: "${MARIADB_USER}"
    password: "${MARIADB_PASSWORD}"
    db: "jira-bus"
    port: "${MARIADB_PORT}"
  mongo:
    url: "mongodb://${MONGO_ROOT_USERNAME}:${MONGO_ROOT_PASSWORD}@mongo:${MONGO_PORT}/admin?authSource=admin"
    database: "keeper"
  influxdb:
    host: "influxdb"
    port: "${INFLUXDB_PORT}"
    user: "${INFLUXDB_USER}"
    pass: "${INFLUXDB_PASSWORD}"
    database: "${INFLUXDB_DB}"
  rabbit:
    user: "${RABBITMQ_USER}"
    pass: "${RABBITMQ_PASSWORD}"
    host: "rabbitmq"
    port: "${RABBITMQ_PORT}"
  minio:
    host: "minio"
    port: "${MINIO_PORT}"
    access: "${MINIO_ROOT_USER}"
    secret: "${MINIO_ROOT_PASSWORD}"
  clickhouse:
    host: "clickhouse"
    port: "${CLICKHOUSE_HTTP_PORT}"
    user: "${CLICKHOUSE_USER}"
    password: "${CLICKHOUSE_PASSWORD}"
    db: "${CLICKHOUSE_DB}"
  disable_email_verification: "${DISABLE_EMAIL_VERIFICATION}"
  force_aws_edp_strip: "${FORCE_AWS_EDP_STRIP}"
  encryption_salt: "${ENCRYPTION_SALT}"
  encryption_salt_auth: "${ENCRYPTION_SALT_AUTH}"
  certificates:
    optscale: ""
  logstash_port: "${LOGSTASH_PORT}"
  events_queue: "${EVENTS_QUEUE}"
  resources_discovery_cache_time: "${RESOURCES_DISCOVERY_CACHE_TIME}"
  token_expiration: "${TOKEN_EXPIRATION}"
  diworker:
    max_report_imports_workers: 10
  stripe:
    api_key: "${STRIPE_API_KEY}"
    webhook_secret: "${STRIPE_WEBHOOK_SECRET}"
    enabled: "${STRIPE_ENABLED}"
