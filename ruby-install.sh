#!/usr/bin/env bash
set -ex
export RUBY_MAJOR=2.7
export RUBY_VERSION=2.7.8
export RUBY_DOWNLOAD_SHA256=c2dab63cbc8f2a05526108ad419efa63a67ed4074dbbcf9fc2b1ca664cb45ba0

RUBY_URL="https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-${RUBY_VERSION}.tar.gz"

DEPS=(
  "autoconf"
  #"automake"
  #"bison"
  "curl"
  "gcc"
  #"gcc-c++"
  #"git"
  #"hostname"
  #"libtool"
  "make"
  #"net-tools"
  #"openssl"
  "openssl-devel"
  #"libffi-devel"
  #"patch"
  #"readline"
  "readline-devel"
  #"util-linux"
  #"wget"
  #"which"
  "zlib-devel"
  "gdbm-devel"
)

mkdir -p /usr/local/etc

# Skip installing gem documentation
echo "gem: --no-ri --no-rdoc" > /usr/local/etc/gemrc

# Install dependent packages.
dnf install -y "${DEPS[@]}" ruby 2>&1

# Download the archive.
cd /tmp && {
  curl -s https://rubygems.org/downloads/openssl-3.0.1.gem --output openssl-3.0.1.gem
  curl -s https://rubygems.org/downloads/digest-3.1.0.gem --output digest-3.1.0.gem
  gem unpack openssl-3.0.1.gem
  gem unpack digest-3.1.0.gem

  curl -s ${RUBY_URL} --output ruby.tar.gz
  echo -e "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c -
  mkdir -p /usr/src/ruby
  tar -zxvf ruby.tar.gz -C /usr/src/ruby --strip-components=1
  rm ruby.tar.gz
}

# Build and install.
cd /usr/src/ruby && {
  rm -rf ext/openssl ext/digest
  cp -rp /tmp/openssl-3.0.1/ext/openssl ./ext/
  cp -rp /tmp/openssl-3.0.1/lib ./ext/openssl/
  cp -rp /tmp/digest-3.1.0/ext/digest ./ext/
  cp -rp /tmp/digest-3.1.0/lib ./ext/digest/

  autoconf && {
    ./configure \
      --disable-install-doc \
      --enable-shared \
      --host=x86_64-pc-linux-gnu \
      --with-ext=openssl,zlib,psych,dbm,gdbm,+
  }
  make -j2
  make install
  rm -rf /tmp/*
}
