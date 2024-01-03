FROM --platform=linux/amd64 fedora:39 AS build

MAINTAINER tigerroll

ARG dir="."
COPY ${dir}/ruby-install.sh /tmp
RUN dnf update -y

RUN bash -x /tmp/ruby-install.sh

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME"
ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH=$GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH

RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

CMD ["irb"]
