#!/usr/bin/env bash
# shellcheck disable=SC2034
# shellcheck disable=SC2154

##########################################################################
# Provider specific settings
#
# NOTE: This file is updated during 'taito project upgrade'. There should
# rarely be need to modify it manually. Modify project.sh, prod-env.sh,
# and testing.sh instead.
##########################################################################

storage_name=$(env | grep '^st_.*_name' | head -n1 | sed 's/.*=//')

case $taito_provider in
  azure)
    taito_plugins="
      azure:-local
      ${taito_plugins}
      azure-storage:-local
      azure-monitoring:-local
    "

    # Kubernetes details
    kubernetes_cluster="${kubernetes_name}"
    kubernetes_user="clusterUser_${taito_zone}_${kubernetes_cluster}"

    # Set Azure specific storage url
    if [[ $taito_env != "local" ]] && [[ $storage_name ]]; then
      taito_storage_url="https://portal.azure.com/#blade/Microsoft_Azure_Storage/ContainerMenuBlade/overview/storageAccountId/%2Fsubscriptions%2F${taito_provider_billing_account_id}%2FresourceGroups%2F${taito_resource_namespace}%2Fproviders%2FMicrosoft.Storage%2FstorageAccounts%2F${taito_project//-/}${taito_env//-/}/path/${storage_name}"
    fi
    ;;
  aws)
    taito_plugins="
      aws:-local
      ${taito_plugins}
      aws-storage:-local
      aws-monitoring:-local
    "

    # Kubernetes details
    kubernetes_cluster="arn:aws:eks:${taito_provider_region}:${taito_provider_org_id}:cluster/${kubernetes_name}"
    kubernetes_user="${kubernetes_cluster}"

    # Set AWS specific storage url
    if [[ $taito_env != "local" ]] && [[ $storage_name ]]; then
      taito_storage_url="https://s3.console.aws.amazon.com/s3/buckets/${storage_name}/?region=${taito_provider_region}&tab=overview"
    fi
    ;;
  "do")
    taito_plugins="
      do:-local
      ${taito_plugins}
    "

    # Kubernetes details
    kubernetes_cluster="TODO_${kubernetes_name}"
    kubernetes_user="${kubernetes_cluster}"
    ;;
  gcp)
    taito_plugins="
      gcp:-local
      gcp-secrets:-local
      ${taito_plugins}
      gcp-storage:-local
      gcp-monitoring:-local
    "

    # Kubernetes
    kubernetes_cluster="gke_${taito_zone}_${taito_provider_region}_${kubernetes_name}"
    kubernetes_user="${kubernetes_cluster}"

    # Database
    gcp_db_proxy_enabled=false # TODO: temporary

    # Storage
    if [[ ${storage_name} ]]; then
      provider_service_account_enabled=true
      # Set google specific storage url
      if [[ $taito_env != "local" ]]; then
        taito_storage_url="https://console.cloud.google.com/storage/browser/${storage_name}?project=$taito_resource_namespace_id"
      fi
    fi

    link_urls="
      ${link_urls}
      * services[:ENV]=https://console.cloud.google.com/apis/dashboard?project=$taito_resource_namespace_id Google services (:ENV)
    "
    ;;
  linux)
    # shellcheck disable=SC1091
    . scripts/linux-provider/taito-provider-config.sh
    ;;
  custom)
    # shellcheck disable=SC1091
    . scripts/custom-provider/taito-provider-config.sh
    ;;
esac

taito_logging_provider=${taito_logging_provider:-$taito_provider}
case $taito_logging_provider in
  azure)
    taito_logging_format=text
    link_urls="
      ${link_urls}
      * logs:ENV=https://portal.azure.com/#@${taito_provider_org_id}/resource/subscriptions/${taito_provider_billing_account_id}/resourceGroups/${taito_zone}/analytics Logs (:ENV)
    "
    ;;
  aws)
    taito_logging_format=text
    if [[ ${kubernetes_name} ]]; then
      link_urls="
        ${link_urls}
        * logs:ENV=https://${taito_provider_region}.console.aws.amazon.com/cloudwatch/home?region=${taito_provider_region}#logStream:group=${kubernetes_name};prefix=kubernetes.var.log.containers.${taito_namespace};streamFilter=typeLogStreamPrefix Logs (:ENV)
      "
    else
      link_urls="
        ${link_urls}
        * logs:ENV=https://${taito_provider_region}.console.aws.amazon.com/cloudwatch/home?region=${taito_provider_region}#logs: Logs (:ENV)
      "
    fi
    ;;
  efk)
    # TODO: EFK running on Kubernetes
    taito_logging_format=text
    ;;
  gcp)
    taito_logging_format=stackdriver
    link_urls="
      ${link_urls}
      * logs:ENV=https://console.cloud.google.com/logs/viewer?project=$taito_zone&minLogLevel=0&expandAll=false&resource=k8s_container%2Fcluster_name%2F$kubernetes_name%2Fnamespace_name%2F$taito_namespace Logs (:ENV)
    "
    ;;
  *)
    taito_logging_format=text
    ;;
esac

case $taito_uptime_provider in
  azure)
    taito_plugins="${taito_plugins/azure:-local/}"
    taito_plugins="
      azure:-local
      ${taito_plugins}
    "
    link_urls="
      ${link_urls}
      * alerts[:ENV]=https://portal.azure.com/#@${taito_provider_org_id}/resource/subscriptions/${taito_provider_billing_account_id}/resourceGroups/${taito_zone}/alerts Alerts (:ENV)
      * uptime[:ENV]=https://portal.azure.com/#blade/AppInsightsExtension/AvailabilityCuratedFrameBlade/id/%2Fsubscriptions%2F${taito_provider_billing_account_id}%2FresourceGroups%2F${taito_zone}%2Fproviders%2FMicrosoft.Insights%2Fwebtests%2F${taito_project}-${taito_env}-client Uptime monitoring (:ENV)
    "
    ;;
  aws)
    taito_plugins="${taito_plugins/aws:-local/}"
    taito_plugins="
      aws:-local
      ${taito_plugins}
    "
    link_urls="
      ${link_urls}
      * uptime[:ENV]=https://console.aws.amazon.com/cloudwatch/home?region=${taito_provider_region}#alarmsV2:?search=${taito_project}-${taito_target_env}&alarmFilter=ALL  Uptime monitoring (:ENV)
    "
    ;;
  gcp)
    taito_plugins="${taito_plugins/gcp:-local/}"
    taito_plugins="
      gcp:-local
      ${taito_plugins}
    "
    link_urls="
      ${link_urls}
      * uptime[:ENV]=https://app.google.stackdriver.com/uptime?project=$taito_zone&f.search=$taito_project Uptime monitoring (:ENV)
    "
    ;;
esac

case $taito_ci_provider in
  azure)
    taito_plugins="
      ${taito_plugins}
      azure-ci:-local
    "
    link_urls="
      ${link_urls}
      * builds=https://dev.azure.com/${taito_ci_organization:-$taito_organization}/${taito_project}/_build Build logs
    "
    ;;
  aws)
    taito_plugins="
      ${taito_plugins}
      aws-ci:-local
    "
    link_urls="
      ${link_urls}
      * builds=https://console.aws.amazon.com/codesuite/codebuild/projects/${taito_project}/history?region=${taito_provider_region} Build logs
    "
    ;;
  bitbucket)
    taito_plugins="
      ${taito_plugins}
      bitbucket-ci:-local
    "
    link_urls="
      ${link_urls}
      * builds=https://$taito_vc_repository_url/addon/pipelines/home Build logs
    "
    ;;
  gcp)
    taito_plugins="
      ${taito_plugins}
      gcp-ci:-local
    "
    link_urls="
      ${link_urls}
      * builds[:ENV]=https://console.cloud.google.com/cloud-build/builds?project=$taito_zone&query=source.repo_source.repo_name%3D%22github_${taito_vc_organization}_$taito_vc_repository%22 Build logs
    "
    ;;
  local)
    link_urls="
      ${link_urls}
      * builds=./local-ci.sh Local CI/CD
    "
    ;;
esac

case $taito_vc_provider in
  bitbucket)
    link_urls="
      ${link_urls}
      * docs=https://$taito_vc_repository_url/wiki/Home Project documentation
      * project=https://$taito_vc_repository_url/addon/trello/trello-board Project management
    "
    ;;
  github)
    link_urls="
      ${link_urls}
      * docs=https://$taito_vc_repository_url/wiki Project documentation
      * project=https://$taito_vc_repository_url/projects Project management
      * releases=https://$taito_vc_repository_url/releases Releases
    "

    # Buildbot token for tagging releases
    if [[ $taito_plugins == *"semantic-release:$taito_env"* ]]; then
      taito_remote_secrets="
        $taito_remote_secrets
        version-control-buildbot.token:read/devops
      "
    fi
    ;;
esac

case $taito_container_registry_provider in
  azure)
    # Enable Azure auth
    taito_plugins="${taito_plugins/azure:-local/}"
    taito_plugins="
      azure:-local
      ${taito_plugins}
    "
    ;;
  aws)
    # Enable AWS auth
    taito_plugins="${taito_plugins/aws:-local/}"
    taito_plugins="
      aws:-local
      ${taito_plugins}
    "
    ;;
  "do")
    # Enable DO auth
    taito_plugins="${taito_plugins/do:-local/}"
    taito_plugins="
      do:-local
      ${taito_plugins}
    "
    ;;
  docker)
    # Enable Docker Hub auth
    taito_plugins="
      docker-registry:-local
      ${taito_plugins}
    "
    ;;
  gcp)
    # Enable gcp auth
    taito_plugins="${taito_plugins/gcp:-local/}"
    taito_plugins="
      gcp:-local
      ${taito_plugins}
    "
    ;;
  local)
    ;;
esac

# Deployment platforms

if [[ ${taito_deployment_platforms} == *"kubernetes"* ]] &&
   [[ ${kubernetes_name:-} ]]
then
  taito_plugins="
    kubectl helm
    ${taito_plugins}
  "
fi

if [[ ${taito_deployment_platforms} == *"docker-compose"* ]]; then
  taito_plugins="
    docker-compose
    ${taito_plugins}
  "
fi

# Sentry
if [[ $taito_plugins == *"sentry"* ]]; then
  sentry_organization=${template_default_sentry_organization}
  link_urls="
    ${link_urls}
    * errors:ENV=https://sentry.io/${template_default_sentry_organization}/$taito_project/?query=is%3Aunresolved+environment%3A$taito_target_env Sentry errors (:ENV)
  "
fi

# Service account
if [[ $provider_service_account_enabled == "true" ]]; then
  taito_provider_service_account_secret=$taito_project-$taito_env-serviceaccount.key
  taito_remote_secrets="
    $taito_remote_secrets
    $taito_provider_service_account_secret:file
  "
else
  provider_service_account_enabled="false"
fi

# Database SSL client key
if [[ $db_database_ssl_client_cert_enabled == "true" ]]; then
  db_database_ssl_ca_secret=$db_database_instance-ssl.ca
  db_database_ssl_cert_secret=$db_database_instance-ssl.cert
  db_database_ssl_key_secret=$db_database_instance-ssl.key
  taito_remote_secrets="
    $taito_remote_secrets
    $db_database_ssl_ca_secret:copy/devops
    $db_database_ssl_cert_secret:copy/devops
    $db_database_ssl_key_secret:copy/devops
  "
fi

# Storage link
if [[ $taito_storage_url ]] && [[ $taito_storage_url != *"localhost"* ]]; then
  link_urls="
    ${link_urls}
    * storage:ENV=$taito_storage_url Storage bucket (:ENV)
  "
fi
