#!/bin/bash

set -eo pipefail

usage() {
cat << EOF

Usage: ${0##*/} [-g [base64 encoded gcloud-key.json]] [-h]

Setup gCloud SDK and configure access.
Requires a gCloud service account from https://console.cloud.google.com/iam-admin/serviceaccounts
these environment variables can optionally be set:
GCLOUD_PROJECT GCLOUD_SERVICE_ACCOUNT GCE_CLUSTER GCE_ZONE

    Instructions:
    1. Select an account with the required priviledges and create a new key from the context menu.
    2. This will download a file, store that in a safe place.
    3. Encode the entire file with base64 and either export an ENV var:
        "export GCLOUD_SERVICE_KEY=\`cat ~/gcloud.json | base64\`"
      or supply on the command line:
        "${0##*/} -g \`cat ~/gcloud.json | base64\`"


    -h              display this help and exit
    -k              gCloud service key
    -p              gCloud project name
    -s              gCloud service account
    -c              gCloud cluster name
    -z              gCloud zone

EOF
}

CLOUDSDK_VERSION='162.0.0'
GSK=$GCLOUD_SERVICE_KEY

# getopts & validations
OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hk:p:s:c:z:" opt; do
  case "$opt" in
    h)
        usage
        exit 0
        ;;
    k)
        GSK=${OPTARG}
        ;;
    p)
        GCLOUD_PROJECT=${OPTARG}
        ;;
    s)
        GCLOUD_SERVICE_ACCOUNT=${OPTARG}
        ;;
    c)
        GCE_CLUSTER=${OPTARG}
        ;;
    z)
        GCE_ZONE=${OPTARG}
        ;;
    \?)
        usage >&2
        exit 1
        ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

if [ -z "$GSK" ]; then
  echo error: no [GCLOUD_SERVICE_KEY] supplied or found in the ENVIRONMENT
  usage
  exit 1
fi

cd $HOME

WORKDIR="$PWD"
OLDDIR=$PWD
cd $WORKDIR
echo "working directory: $PWD"

if hash gcloud 2>/dev/null; then
    echo "using existing gcloud command"
else
    echo "installing gCloud SDK"
    wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$CLOUDSDK_VERSION-linux-x86_64.tar.gz
    tar -zxf google-cloud-sdk-$CLOUDSDK_VERSION-linux-x86_64.tar.gz
fi

declare -a vars=(GCLOUD_PROJECT GCLOUD_SERVICE_ACCOUNT GCE_CLUSTER GCE_ZONE)

for var_name in "${vars[@]}"
do
  if [ -z "${!var_name}" ]; then
    echo "Missing option or environment variable or config key $var_name"
    usage >&2
    exit 1
  fi
done

echo $GCLOUD_SERVICE_KEY | base64 --decode > ${HOME}/gcloud-service-key.json
gcloud config set --installation component_manager/disable_update_check true
gcloud auth activate-service-account --key-file ${HOME}/gcloud-service-key.json
GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcloud-service-key.json
CLOUDSDK_CONTAINER_USE_CLIENT_CERTIFICATE=True
gcloud config set project $GCLOUD_PROJECT
gcloud config set account $GCLOUD_SERVICE_ACCOUNT
gcloud container clusters get-credentials $GCE_CLUSTER --zone $GCE_ZONE --project $GCLOUD_PROJECT

cd $OLDDIR