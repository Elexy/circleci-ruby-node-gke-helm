#!/bin/bash

set -euo pipefail

usage() {
cat << EOF

Usage: ${0##*/} [-g [base64 encoded gcloud-key.json]] [-h]

Setup gCloud SDK and configure access.
Requires a gCloud service from https://console.cloud.google.com/iam-admin/serviceaccounts

    Instructions:
    1. Select an account with the required priviledges and create a new key from the context menu.
    2. This will download a file, store that in a safe place.
    3. Encode the entire file with base64 and either export an ENV var:
        "export GCLOUD_SERVICE_KEY=`cat ~/gcloud.json | base64`"
      or supply on the command line:
        "${0##*/} -g `cat ~/gcloud.json | base64`"


    -h              display this help and exit
    -g              gCloud service key

EOF
}

# getopts & validations
OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hg:" opt; do
  case "$opt" in
    h)
        usage
        exit 0
        ;;
    g)
        GCLOUD_SERVICE_KEY=${OPTARG}
        ;;
    \?)
        usage >&2
        exit 1
        ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

if [ -z "$GCLOUD_SERVICE_KEY" ]; then
  echo error: no [GCLOUD_SERVICE_KEY] supplied of found in the ENV
  usage
  exit 1
fi

cd $HOME

WORKDIR="$PWD"
OLDDIR=$PWD
cd $WORKDIR
echo "working directory: $PWD"

echo "installing gCloud SDK"
wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-156.0.0-linux-x86_64.tar.gz
tar -zxf google-cloud-sdk-156.0.0-linux-x86_64.tar.gz

echo $GCLOUD_SERVICE_KEY | base64 --decode > ${HOME}/gcloud-service-key.json
chmod -R 777 ./google-cloud-sdk
export PATH=${HOME}/google-cloud-sdk/bin:$PATH

cd $OLDDIR