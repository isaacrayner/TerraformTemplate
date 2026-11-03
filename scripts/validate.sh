#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TF_IN_AUTOMATION=1

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required (>= 1.5.0)" >&2
  exit 127
fi

terraform -chdir="${repository_root}" fmt -check -recursive

validated=0
while IFS= read -r module_directory; do
  terraform_files=("${module_directory}"/*.tf)

  # README-only directories are catalog candidates, not Terraform modules.
  if [[ ! -e "${terraform_files[0]}" ]]; then
    continue
  fi

  for required_file in main.tf variables.tf outputs.tf versions.tf README.md; do
    if [[ ! -f "${module_directory}/${required_file}" ]]; then
      echo "Incomplete module: ${module_directory#"${repository_root}/"} is missing ${required_file}" >&2
      exit 1
    fi
  done

  echo "Validating ${module_directory#"${repository_root}/"}"
  terraform -chdir="${module_directory}" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="${module_directory}" validate -no-color
  validated=$((validated + 1))
done < <(find "${repository_root}/modules" -mindepth 1 -maxdepth 1 -type d | sort)

echo "Validating deployments/_template"
terraform -chdir="${repository_root}/deployments/_template" init -backend=false -input=false -no-color >/dev/null
terraform -chdir="${repository_root}/deployments/_template" validate -no-color

echo "Validated ${validated} implemented modules and the deployment template."
