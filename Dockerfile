FROM circleci/ruby:2-node

ENV CLOUD_SDK_VERSION 162.0.0
ENV HELM_VERSION v2.5.0

ADD ./scripts /src/circleci/scripts

USER root
RUN ln -s /usr/local/bin/ruby /usr/bin/ruby && \
    chown circleci:circleci /src/circleci && \
    cd /src/circleci/scripts && \
    bundle install --gemfile=gemfile

USER circleci

RUN cd /src/circleci && \
  wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$CLOUD_SDK_VERSION-linux-x86_64.tar.gz && \
  tar -zxf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
  rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
  ./google-cloud-sdk/install.sh --quiet --additional-components kubectl docker-credential-gcr && \
  wget https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz && \
  tar -zxvf helm-$HELM_VERSION-linux-amd64.tar.gz && \
  mkdir /src/circleci/bin && \
  mv linux-amd64/helm /src/circleci/bin/helm

ENV PATH="/src/circleci/google-cloud-sdk/bin:/src/circleci/bin::$PATH"

