#!/bin/sh -l

set -eu

function subcommandTerraform {
  VERSION=$(tfupdate release latest hashicorp/terraform)

  UPDATE_MESSAGE="[tfupdate] Update terraform to v${VERSION}"
  if hub pr list -s "open" -f "%t: %U%n" | grep -F "$UPDATE_MESSAGE"; then
    echo "A pull request already exists"
  elif hub pr list -s "merged" -f "%t: %U%n" | grep -F "$UPDATE_MESSAGE"; then
    echo "A pull request is already merged"
  else
    git checkout -b update-terraform-to-v${VERSION} origin/${PR_BASE_BRANCH}
    tfupdate terraform -v ${VERSION} ${TFUPDATE_OPTIONS} ${TFUPDATE_PATH}

    if git add . && git diff --cached --exit-code --quiet; then
      echo "No changes"
    else
      if [ "${UPDATE_TFENV_VERSION_FILES}" == "1" ]; then
        for UPDATED_HCL in $(git diff --cached --name-only); do
          TFENV_VERSION_FILE="$(dirname $UPDATED_HCL)/.terraform-version"
          if [ -f "$TFENV_VERSION_FILE" ]; then
            echo "$VERSION" > "$TFENV_VERSION_FILE"
          fi
        done
        if [ -f ".terraform-version" ]; then
          echo "$VERSION" > ".terraform-version"
        fi
        git add .
      fi

      git commit -m "$UPDATE_MESSAGE"
      PR_BODY="For details see: https://github.com/hashicorp/terraform/releases"
      git push origin HEAD && hub pull-request -m "$UPDATE_MESSAGE" -m "$PR_BODY" -b ${PR_BASE_BRANCH}
    fi
  fi
}

function subcommandProvider {
  VERSION=$(tfupdate release latest terraform-providers/terraform-provider-${TFUPDATE_PROVIDER_NAME})

  UPDATE_MESSAGE="[tfupdate] Update terraform-provider-${TFUPDATE_PROVIDER_NAME} to v${VERSION}"
  if hub pr list -s "open" -f "%t: %U%n" | grep -F "$UPDATE_MESSAGE"; then
    echo "A pull request already exists"
  elif hub pr list -s "merged" -f "%t: %U%n" | grep -F "$UPDATE_MESSAGE"; then
    echo "A pull request is already merged"
  else
    git checkout -b update-terraform-provider-${TFUPDATE_PROVIDER_NAME}-to-v${VERSION} origin/${PR_BASE_BRANCH}
    tfupdate provider ${TFUPDATE_PROVIDER_NAME} -v ${VERSION} ${TFUPDATE_OPTIONS} ${TFUPDATE_PATH}
    if git add . && git diff --cached --exit-code --quiet; then
      echo "No changes"
    else
      git commit -m "$UPDATE_MESSAGE"
      PULL_REQUEST_BODY="For details see: https://github.com/terraform-providers/terraform-provider-${TFUPDATE_PROVIDER_NAME}/releases"
      git push origin HEAD && hub pull-request -m "$UPDATE_MESSAGE" -m "$PULL_REQUEST_BODY" -b ${PR_BASE_BRANCH}
    fi
  fi
}

TFUPDATE_SUBCOMMAND=""
if [ "${INPUT_TFUPDATE_SUBCOMMAND}" != "" ]; then
  TFUPDATE_SUBCOMMAND=${INPUT_TFUPDATE_SUBCOMMAND}
else
  echo "tfupdate_subcommand is required"
  exit 1
fi

TFUPDATE_PATH="."
if [ "${INPUT_TFUPDATE_PATH}" != "" ]; then
  TFUPDATE_PATH=${INPUT_TFUPDATE_PATH}
fi

TFUPDATE_OPTIONS=""
if [ "${INPUT_TFUPDATE_OPTIONS}" != "" ]; then
  TFUPDATE_OPTIONS=${INPUT_TFUPDATE_OPTIONS}
fi

TFUPDATE_PROVIDER_NAME=""
if [ "${INPUT_TFUPDATE_PROVIDER_NAME}" != "" ]; then
  TFUPDATE_PROVIDER_NAME=${INPUT_TFUPDATE_PROVIDER_NAME}
fi
if [ "${TFUPDATE_PROVIDER_NAME}" == "" ] && [ "${TFUPDATE_SUBCOMMAND}" == "provider" ]; then
  echo "tfupdate_provider_name is required if you are using the provider subcommand"
  exit 1
fi

UPDATE_TFENV_VERSION_FILES=0
if [ "${INPUT_UPDATE_TFENV_VERSION_FILES}" == "1" ] || [ "${INPUT_UPDATE_TFENV_VERSION_FILES}" == "true" ]; then
  UPDATE_TFENV_VERSION_FILES=1
fi

PR_BASE_BRANCH="${GITHUB_REF##*/}"
if [ "${INPUT_PR_BASE_BRANCH}" != "" ]; then
  PR_BASE_BRANCH=${INPUT_PR_BASE_BRANCH}
fi

GITHUB_TOKEN=""
if [ "${INPUT_GITHUB_TOKEN}" != "" ]; then
  GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
else
  echo "github_token is required"
  exit 1
fi

cd ${GITHUB_WORKSPACE}/

export GITHUB_TOKEN
git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"

tfupdate --version
hub --version

case "${TFUPDATE_SUBCOMMAND}" in
  terraform)
    subcommandTerraform
    ;;
  provider)
    subcommandProvider
    ;;
  *)
    echo "invalid tfupdate_subcommand is provided"
    exit 1
    ;;
esac

