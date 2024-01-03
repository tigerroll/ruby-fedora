#!/usr/bin/env bash
set -ex
export RUBY_MAJOR=2.7
export RUBY_VERSION=2.7.8
export RUBY_DOWNLOAD_SHA256=c2dab63cbc8f2a05526108ad419efa63a67ed4074dbbcf9fc2b1ca664cb45ba0

RUBY_URL="https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-${RUBY_VERSION}.tar.gz"

DEPS=(
  "autoconf"
  "gcc"
  "make"
  "openssl-devel"
  "libffi-devel"
  "readline-devel"
  "tar"
  "gzip"
  "wget"
  "zlib-devel"
  "gdbm-devel"
)

function gem_unpack() {
  gem_name=$1
  tar -xvf ${gem_name}.gem -C ${gem_name} && {
    cd ${gem_name}
    gunzip checksums.yaml.gz metadata.gz
    tar -zxvf data.tar.gz
    return $?
  }
}

# Install dependent packages.
dnf install -y "${DEPS[@]}" 2>&1

# Download the archive.
cd /tmp && {
  curl -s ${RUBY_URL} --output ruby.tar.gz
  echo -e "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c -
  install -d /usr/local/src/ruby
  tar -zxvf ruby.tar.gz -C /usr/local/src/ruby --strip-components=1

  curl -s https://rubygems.org/downloads/openssl-3.0.1.gem --output openssl.gem
  curl -s https://rubygems.org/downloads/digest-3.1.0.gem --output digest.gem

  mkdir openssl digest

  gem_unpack openssl
  gem_unpack digest

  rm ruby.tar.gz
}

# Build and install.
cd /usr/local/src/ruby && {
  rm -rf ext/openssl ext/digest
  cp -rp /tmp/openssl/ext/openssl ./ext/
  cp -rp /tmp/openssl/lib ./ext/openssl/
  cp -rp /tmp/digest/ext/digest ./ext/
  cp -rp /tmp/digest/lib ./ext/digest/

  ./configure
  make -j2
  make install
  rm -rf /tmp/*
}
