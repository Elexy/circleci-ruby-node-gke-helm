# ruby-node-gcloud

This repo builds a utility image for use in CI environments like CircleCI. It is based on circle/ruby:2-node but adds the gCloud SDK. As part of the gCloud SDK, kubectl, helm and docker-credential-gcr are installed.
Some convenience scripts, for the circlci user, are available in the ~/scripts cirectory.

## scripts
Scripts reside under ~/scripts

### init_gce.sh
Installs the gCoud SDK if needed and configures kubectl access to a provided project and Google Container Engine cluster

### update_chart_config.rb


### init_gce.sh

### init_gce.sh