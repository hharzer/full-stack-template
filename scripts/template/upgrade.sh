#!/bin/sh

: "${template_project_path:?}"
: "${template_project:?}"

echo
./scripts/template/init.sh

echo "- upgrade: Copy files from template to project"
cp README.md "${template_project_path}"
cp cloudbuild.yaml "${template_project_path}"
mkdir -p "${template_project_path}/scripts"
rm -rf "${template_project_path}/scripts/${template_repo_name}" 2> /dev/null
cp -r "scripts/${template_repo_name}" "${template_project_path}/scripts/${template_repo_name}" 2> /dev/null

echo