#!/bin/sh

# parse branch
if [ -f $GITHUB_EVENT_PATH ]; then
  # TODO: remove, for debugging only
  cat $GITHUB_EVENT_PATH

  touch /tmp/variables.json

  # Codefresh system provided variables
  # https://codefresh.io/docs/docs/codefresh-yaml/variables/#system-provided-variables
  REPO_OWNER=$(cat $GITHUB_EVENT_PATH | jq -r .repository.organization)
  REPO_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .repository.name)
  
  REVISION=$(cat $GITHUB_EVENT_PATH | jq -r .head_commit.id)
  SHORT_REVISION=$(echo $REVISION | cut -c 2-8)

  # in case of push event
  BRANCH=$(cat $GITHUB_EVENT_PATH | jq -r .ref | awk -F '/' '{print $3}')
  NORMALIZED_BRANCH=$(echo $BRANCH | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g')

  jq -n --arg revision $REVISION --arg repo_owner $REPO_OWNER --arg repo_name $REPO_NAME  \
    '[{"CF_REVISION":"\($revision)", "CF_REPO_OWNER": "\($repo_owner)", "CF_REPO_NAME": "\($repo_name)"}]' > /tmp/variables.json

  # NOTE: there's probably a better way of doing this, but doing this to avoid super long running jq command
  echo $(cat /tmp/variables.json | jq --arg norm_branch $NORMALIZED_BRANCH '[.[0] + {"CF_BRANCH_TAG_NORMALIZED": "\($norm_branch)"}]') > /tmp/variables.json
  echo $(cat /tmp/variables.json | jq --arg short_revision $SHORT_REVISION '[.[0] + {"CF_SHORT_REVISION": "\($short_revision)"}]') > /tmp/variables.json

  # Env vars set with prefix 'CFVAR_' will be set as variables passed into codefresh with the 'CFVAR_' prefix removed
  # i.e. CFVAR_HELM_REPO_NAME=my-helm-repo will be passed to Codefresh as HELM_REPO_NAME=my-helm-repo
  # for var in "${!CFVAR_@}"; do
  #   echo $(cat /tmp/variables.json | jq --arg key ${var#"CFVAR_"} --arg value ${!var} '[.[0] + {"\($key)": "\($value)"}]') > /tmp/variables.json
  # done

  cat /tmp/variables.json

  if [ -z "$BRANCH" ]
    then
      # in case of pull request event
      BRANCH=$(cat $GITHUB_EVENT_PATH | jq -r head.ref)
    fi
else
  echo "Required file on path 'GITHUB_EVENT_PATH' not exists"
fi
codefresh auth create-context context --api-key $CF_API_KEY
codefresh auth use-context context


if [ -n "$TRIGGER_NAME" ]
then
  codefresh run $PIPELINE_ID --trigger=$TRIGGER_NAME --branch=$BRANCH --var-file=/tmp/variables.json
else
  codefresh run $PIPELINE_ID --branch=$BRANCH --var-file=/tmp/variables.json
fi
