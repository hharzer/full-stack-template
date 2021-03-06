#!/bin/bash -e
: "${taito_company:?}"
: "${taito_vc_repository:?}"
: "${taito_vc_repository_alt:?}"

if [[ ${taito_verbose:-} == "true" ]]; then
  set -x
fi

# Function not supported yet
rm -rf function
sed -i "s/ function / /" scripts/taito/config/main.sh
sed -i "s/ function / /" scripts/taito/project.sh

# Remote the example site
rm -rf www/site
sed -i '/\/site\/node_modules" # FOR GATSBY ONLY/d' docker-compose.yaml
sed -i '/\/site\/node_modules" # FOR GATSBY ONLY/d' docker-compose-remote.yaml

echo
echo "######################"
echo "#    Choose stack"
echo "######################"
echo
echo "If you are unsure, just accept the defaults."
echo

function prune () {
  local message=$1
  local name=$2
  local path=$3
  local path2=$4

  echo
  read -r -t 1 -n 1000 || :
  read -p "$message" -n 1 -r confirm
  if ( [[ "$message" == *"[y/N]"* ]] && ! [[ "${confirm}" =~ ^[Yy]$ ]] ) || \
     ( [[ "$message" == *"[Y/n]"* ]] && ! [[ "${confirm}" =~ ^[Yy]*$ ]] ); then
    echo
    echo "  Removing ${name}..."
    if [[ $path ]]; then
      sed -i "/^        location $path {\r*\$/,/^        }\r*$/d" docker-nginx.conf
    fi
    if [[ $path2 ]]; then
      sed -i "/^        location $path2 {\r*\$/,/^        }\r*$/d" docker-nginx.conf
    fi

    sed -i "/^  full-stack-template-$name:\r*\$/,/^\r*$/d" docker-compose.yaml
    sed -i "/^  full-stack-template-$name:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
    sed -i "/^  # full-stack-template-$name:\r*\$/,/^\r*$/d" docker-compose.yaml
    sed -i "/^  # full-stack-template-$name:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
    if [[ -f docker-compose-test.yaml ]]; then
      sed -i "/^  full-stack-template-$name-test:\r*\$/,/^\r*$/d" docker-compose-test.yaml
      sed -i "/^  # full-stack-template-$name-test:\r*\$/,/^\r*$/d" docker-compose-test.yaml
    fi
    sed -i "/^    $name:\r*\$/,/^\r*$/d" ./scripts/helm.yaml
    sed -i "/-$name$/d" ./scripts/helm.yaml

    sed -i "s/ $name / /" scripts/taito/config/main.sh
    sed -i "s/ $name / /" scripts/taito/project.sh
    sed -i "s/ \\/$name\\/uptimez / /" scripts/taito/config/main.sh
    sed -i "s/ \\/$name\\/uptimez / /" scripts/taito/project.sh

    sed -i "/\\* $name/d" scripts/taito/project.sh
    sed -i "/test_$name/d" scripts/taito/testing.sh

    sed -i "/:$name\":/d" package.json
    sed -i "s/install-all:$name //g" package.json
    sed -i "s/lint:$name //g" package.json
    sed -i "s/unit:$name //g" package.json
    sed -i "s/test:$name //g" package.json
    sed -i "s/\\\\\"check-deps:$name {@}\\\\\" //g" package.json
    sed -i "s/\\\\\"check-size:$name {@}\\\\\" //g" package.json
    sed -i "s/ && npm run clean:$name//g" package.json

    # Prune target from CI/CD scripts
    sed -i "/^action \"artifact:$name\"/,/^}$/d" .github/main.workflow
    sed -i "/taito artifact prepare:$name/d" azure-pipelines.yml
    sed -i "/taito artifact release:$name/d" azure-pipelines.yml
    sed -i "/- step: # $name prepare/,/$name-tester.docker/d" bitbucket-pipelines.yml
    sed -i "/- step: # $name release/,/taito artifact release:$name/d" bitbucket-pipelines.yml
    sed -i "/taito artifact prepare:$name/d" buildspec.yml
    sed -i "/taito artifact release:$name/d" buildspec.yml
    sed -i "/^- id: artifact-prepare-$name\r*\$/,/^\r*$/d" cloudbuild.yaml
    sed -i "/^- id: artifact-release-$name\r*\$/,/^\r*$/d" cloudbuild.yaml
    sed -i "/REPO_NAME\\/$name:/d" cloudbuild.yaml
    # TODO PRUNE .gitlab-ci.yml
    # TODO PRUNE Jenkinsfile
    sed -i "/:$name:/d" local-ci.sh
    # TODO PRUNE .travis.yml

    if [[ $name == "client" ]]; then
      sed -i "s/ \\/uptimez / /" scripts/taito/config/main.sh
      sed -i "s/ \\/uptimez / /" scripts/taito/project.sh
      sed -i "/CYPRESS/d" scripts/taito/testing.sh
      sed -i "/cypress/d" scripts/taito/testing.sh
    fi

    if [[ $name == "server" ]]; then
      sed -i "s/ \\/api\\/uptimez / /" scripts/taito/config/main.sh
      sed -i "s/ \\/api\\/uptimez / /" scripts/taito/project.sh
      sed -i "s/ \\/api\\/docs / /" scripts/taito/config/main.sh
      sed -i "s/ \\/api\\/docs / /" scripts/taito/project.sh
      sed -i '/* apidocs/d' scripts/taito/project.sh
    fi

    if [[ $name == "kafka" ]]; then
      sed -i "/KAFKA/d" docker-compose.yaml
      sed -i "/KAFKA/d" docker-compose-remote.yaml
      sed -i "/KAFKA/d" ./scripts/helm.yaml

      # Remove also Zookeeper
      sed -i "s/ zookeeper / /" scripts/taito/config/main.sh
      sed -i "s/ zookeeper / /" scripts/taito/project.sh
      sed -i "/^  full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose.yaml
      sed -i "/^  full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
      sed -i "/^  # full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose.yaml
      sed -i "/^  # full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
      sed -i "/^    zookeeper:\r*\$/,/^\r*$/d" ./scripts/helm.yaml
    fi

    if [[ $name == "www" ]]; then
      sed -i "s/ \\/docs\\/uptimez / /" scripts/taito/config/main.sh
      sed -i "s/ \\/docs\\/uptimez / /" scripts/taito/project.sh
    fi

    if [[ $name == "database" ]]; then
      sed -i '/postgres-db/d' scripts/taito/config/main.sh
      sed -i '/db_/d' scripts/taito/config/main.sh
      sed -i '/db_/d' scripts/taito/project.sh
      sed -i "/DATABASE/d" scripts/taito/testing.sh
      sed -i '/Database/d' docker-compose.yaml
      sed -i '/Database/d' docker-compose-remote.yaml
      sed -i '/DATABASE_/d' docker-compose.yaml
      sed -i '/DATABASE_/d' docker-compose-remote.yaml
      sed -i '/db_/d' docker-compose.yaml
      sed -i '/db_/d' docker-compose-remote.yaml
      sed -i '/DATABASE_/d' ./scripts/helm.yaml
      sed -i "/^      db:\r*\$/,/^\r*        proxySecret:.*$/d" ./scripts/helm.yaml
      rm -f docker-compose-test.yaml

      # Remove database from server implementation
      # TODO: works only for the default Node.js server implementation
      sed -i '/pg-promise/d' ./server/package.json &> /dev/null || :
      sed -i '/types\\pg/d' ./server/package.json &> /dev/null || :
      sed -i '/db/d' ./server/src/server.ts &> /dev/null || :
      sed -i '/Db/d' ./server/src/common/types.ts &> /dev/null || :
      sed -i '/Database/d' ./server/src/common/types.ts &> /dev/null || :
      sed -i '/state.db/d' ./server/src/infra/InfraRouter.ts &> /dev/null || :
      rm -f ./server/src/common/db.ts &> /dev/null || :
    fi

    if [[ $name == "storage" ]]; then
      # Remove storage from configs
      sed -i "s/service_account_enabled=true/service_account_enabled=false/" scripts/taito/config/main.sh
      sed -i '/storage/d' scripts/taito/config/main.sh
      sed -i '/* storage/d' scripts/taito/config/main.sh
      sed -i '/storage/d' scripts/taito/project.sh
      sed -i '/S3_/d' docker-compose.yaml
      sed -i '/S3_/d' docker-compose-remote.yaml
      sed -i '/storage/d' docker-compose.yaml
      sed -i '/storage/d' docker-compose-remote.yaml
      sed -i '/S3_/d' ./scripts/helm.yaml

      # Remove storage from server implementation
      # TODO: works only for the default Node.js server implementation
      sed -i '/aws-sdk/d' ./server/package.json &> /dev/null || :
      sed -i '/storage/d' ./server/src/server.ts &> /dev/null || :
      sed -i '/storage/d' ./server/src/common/types.ts &> /dev/null || :
      sed -i '/Storage/d' ./server/src/common/config.ts &> /dev/null || :
      sed -i '/S3_/d' ./server/src/common/config.ts &> /dev/null || :
      sed -i '/storage/d' ./server/src/infra/InfraRouter.ts &> /dev/null || :
      sed -i '/storage/d' ./server/src/types/koa.d.ts &> /dev/null || :
      rm -f ./server/src/common/storage.ts &> /dev/null || :
    fi

    rm -rf "$name"
  else
    if [[ $name == "storage" ]] && (
         [[ ${taito_provider:?} == "azure" ]] ||
         [[ ${taito_provider} == "aws" ]]
       ); then
      # Define access key and secret key for AWS (not using minio as proxy)
      sed -i '/storage.accessKeyId/d' scripts/taito/project.sh
      sed -i '/storage.secretKey/d' scripts/taito/project.sh
      sed -i '/^taito_remote_secrets=/a\  $taito_project-$taito_env-storage.secretKey:manual' scripts/taito/project.sh
      sed -i '/^taito_remote_secrets=/a\  $taito_project-$taito_env-storage.accessKeyId:manual' scripts/taito/project.sh
      sed -i '/^taito_local_secrets=/a\  $taito_project-$taito_env-storage.secretKey:random' scripts/taito/project.sh
      sed -i '/^taito_local_secrets=/a\  $taito_project-$taito_env-storage.accessKeyId:random' scripts/taito/project.sh

      if [[ ${taito_provider} == "azure" ]]; then
        # Use minio as azure gateway instead of gcs gateway
        sed -i 's/- gcs/- azure/' scripts/helm.yaml
        sed -i '/- ${taito_resource_namespace}/d' scripts/helm.yaml
      elif [[ ${taito_provider} == "aws" ]]; then
        # Remove minio proxy
        sed -i "/^    storage:\r*\$/,/^\r*$/d" ./scripts/helm.yaml
        sed -i '/S3_URL/d' ./scripts/helm.yaml
      fi
    fi
    if [[ $name == "kafka" ]]; then
      echo
      read -r -t 1 -n 1000 || :
      read -p "Use external Kafka cluster? [Y/n] " -n 1 -r confirm
      if [[ ${confirm} =~ ^[Yy]*$ ]]; then
        sed -i "s/KAFKA_HOST:.*$/KAFKA_HOST: kafka.kafka.svc.cluster.local/g" \
          ./scripts/helm.yaml
        sed -i "/^    $name:\r*\$/,/^\r*$/d" ./scripts/helm.yaml
        sed -i "/^    zookeeper:\r*\$/,/^\r*$/d" ./scripts/helm.yaml

        sed -i "/^  full-stack-template-kafka:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
        sed -i "/^  # full-stack-template-kafka:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
        sed -i "/^  full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
        sed -i "/^  # full-stack-template-zookeeper:\r*\$/,/^\r*$/d" docker-compose-remote.yaml
      fi
    fi
  fi
}

prune "WEB user interface? [Y/n] " client \\/
prune "Administration GUI? [y/N] " admin \\/admin
prune "Static website (e.g. for API documentation or user guide)? [y/N] " www \\/docs

echo
echo "NOTE: WEB user interface is just a bunch of static files that are loaded"
echo "to a web browser. If you need some process running on server or need to"
echo "keep some secrets hidden from browser, you need API/server."
echo

prune "API/services? [Y/n] " server \\/api
prune "GraphQL gateway? [y/N] " graphql \\/graphql
prune "Kafka for event-based streaming/queuing? [y/N] " kafka
prune "Redis (e.g. as in-memory cache)? [y/N] " redis
prune "Worker for background jobs? [y/N] " worker
prune "Relational database? [Y/n] " database
prune "Permanent object storage for files? [y/N] " storage \\/bucket \\/minio

echo
echo "Replacing project and company names in files. Please wait..."
find . -type f -exec sed -i \
  -e "s/full_stack_template/${taito_vc_repository_alt}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/full-stack-template/${taito_vc_repository}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/companyname/${taito_company}/g" 2> /dev/null {} \;
find . -type f -exec sed -i \
  -e "s/FULL-STACK-TEMPLATE/full-stack-template/g" 2> /dev/null {} \;

echo "Generating unique random ports (avoid conflicts with other projects)..."
if [[ ! $ingress_port ]]; then ingress_port=$(shuf -i 8000-9999 -n 1); fi
if [[ ! $db_port ]]; then db_port=$(shuf -i 6000-7999 -n 1); fi
if [[ ! $www_port ]]; then www_port=$(shuf -i 5000-5999 -n 1); fi
sed -i "s/7463/${www_port}/g" scripts/taito/config/main.sh docker-compose.yaml \
  scripts/taito/TAITOLESS.md www/README.md &> /dev/null || :
sed -i "s/6000/${db_port}/g" scripts/taito/config/main.sh docker-compose.yaml \
  scripts/taito/TAITOLESS.md &> /dev/null || :
sed -i "s/9999/${ingress_port}/g" scripts/taito/config/main.sh docker-compose.yaml \
  scripts/taito/TAITOLESS.md &> /dev/null || :

./scripts/taito-template/common.sh
echo init done
