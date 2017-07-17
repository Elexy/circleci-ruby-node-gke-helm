#!/bin/bash

set -e

usage() {
cat << EOF

Usage: ${0##*/} -c [chart name] [-h]

Detect the name of the currently deployed release for a chart

    -h              display this help and exit
    -c              chart name

EOF
}

CHART=''

# getopts & validations
OPTIND=1 # Reset is necessary if getopts was used previously in the script.  It is a good idea to make this local in a function.
while getopts "hc:" opt; do
  case "$opt" in
    h)
        usage
        exit 0
        ;;
    c)
        CHART=${OPTARG}
        ;;
    \?)
        usage >&2
        exit 1
        ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional --.

if [ -z "$CHART" ]; then
  echo error: no chart name supplied with -c
  usage
  exit 1
fi

RELEASE=`helm ls | grep $CHART | awk '{print $1}'`
if [ -z "$RELEASE" ]; then
  echo error: I didn\'t find a helm chart with name [$CHART] deployed in the cluster
else
  printf "%s" $RELEASE
fi

