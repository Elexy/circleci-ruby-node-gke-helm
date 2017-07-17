#!/bin/bash

set -e

RELEASE=`helm ls | grep dgs | awk '{print $1}'`
printf "%s" $RELEASE
