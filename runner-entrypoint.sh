#!/bin/sh

# parse branch
if [ -f $GITHUB_EVENT_PATH ]; then
  # TODO: remove, for debugging only
	cat $GITHUB_EVENT_PATH

	touch /tmp/variables.yaml

	# Codefresh system provided variables
	# https://codefresh.io/docs/docs/codefresh-yaml/variables/#system-provided-variables
	echo -e "- CF_REVISION=$(cat $GITHUB_EVENT_PATH | jq -r .head_commit.id)\n" > /tmp/variables.yaml
	echo -e "  CF_REPO_OWNER=$(cat $GITHUB_EVENT_PATH | jq -r .repository.organization)\n" > /tmp/variables.yaml
	echo -e "  CF_REPO_NAME=$(cat $GITHUB_EVENT_PATH | jq -r .repository.name)\n" > /tmp/variables.yaml

	# in case of push event
	BRANCH=$(cat $GITHUB_EVENT_PATH | jq -r .ref | awk -F '/' '{print $3}')

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
	codefresh run $PIPELINE_ID --trigger=$TRIGGER_NAME --branch=$BRANCH --var-file=/tmp/variables.yaml
else
	codefresh run $PIPELINE_ID --branch=$BRANCH --var-file=/tmp/variables.yaml
fi
