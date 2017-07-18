# circleci-ruby-node-gke-helm

This repo builds a utility image for use in CI environments like CircleCI. It is based on circle/ruby:2-node but adds the gCloud SDK. As part of the gCloud SDK, kubectl, helm and docker-credential-gcr are installed.
Some convenience scripts, for the circlci user, are available in the ~/scripts cirectory.

## scripts
Scripts reside under /home/circleci/scripts

### init_gce.sh
Installs the gCoud SDK if needed and configures kubectl access to a provided project and Google Container Engine cluster. Example:
```docker run -e GCLOUD_SERVICE_KEY=`cat ~/gcloud.json | base64` elexy/circleci-ruby-node-gke-helm ./scripts/init_gce.sh -p gcloud-project -s some@some.iam.gserviceaccount.com -c cluster-name -z gce-zone```

### update_chart_config.rb
This command can be used to update a helm chart configuration (values.yaml) that you keep in a separate repo. It pulls the repo , then looks for a values.yaml inside the `chartPath`. It will then look for a root property named `projectName` and then update the `tag` for that. The `user` and `email` are used for git identification.

Example:

```docker run -it -v ~/.ssh:/home/circleci/.ssh elexy/circleci-ruby-node-gke-helm ./scripts/update-chart-config.rb -r 'git@github.com:myorg/myrepo.git'  -b someBranch -p projectName -t tag -c chartPath -u 'My Name' -e 'my.name@something.com'```