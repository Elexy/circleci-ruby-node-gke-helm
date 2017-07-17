FROM circleci/ruby:2-node

ENV CLOUD_SDK_VERSION 162.0.0
ENV HELM_VERSION v2.5.0

USER root

RUN cd /opt && \
  wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$CLOUD_SDK_VERSION-linux-x86_64.tar.gz && \
  tar -zxf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
  rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
  ./google-cloud-sdk/install.sh --quiet --additional-components kubectl docker-credential-gcr && \
  wget https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz && \
  tar -zxvf helm-$HELM_VERSION-linux-amd64.tar.gz && \
  mv linux-amd64/helm /usr/local/bin/helm

ENV PATH="/opt/google-cloud-sdk/bin:$PATH"

ADD ./scripts /home/circleci/scripts

RUN ln -s /usr/local/bin/ruby /usr/bin/ruby && \
  chown circleci:circleci /home/circleci -R

WORKDIR /home/circleci
USER circleci

RUN cd ~ && \
  bundle install --gemfile=scripts/gemfile --path=vendor

