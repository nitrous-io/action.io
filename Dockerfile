# From here, until the final two RUN steps will be it's own Dockerfile which will be
# pre-built and put up in our private registry so while running specs, we will only 
# run the final two RUN steps

FROM ubuntu

# Set env variables required for Ruby
ENV RUBY_BUILD_VERSION 20131220
ENV RUBY_VERSION 2.1.0-rc1
ENV PATH /usr/local/lib/$RUBY_VERSION/bin:$PATH
ENV LANGUAGE en_US.UTF-8

# Set env variables required for Postgres
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Set working directory to /var/apps/action.io (that is where the app will be built from)
WORKDIR /var/apps/action.io

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

# Install global dependencies
RUN apt-get install -yy build-essential autoconf curl wget git-core

# Install default locales
RUN \
    locale-gen en_US.UTF-8 &&\
    dpkg-reconfigure locales

# Install Ruby Dependencies
RUN apt-get install -yy libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

# Install all hard dependencies required by action.io
RUN apt-get install -yy qt3-dev-tools libqt4-dev

# Install Postgres (and configure to set no password for the postgres user)
RUN \
  apt-get install -yy postgresql postgresql-common postgresql-client libpq-dev libpq5 &&\
  sed -i 's/peer\|md5/trust/g' /etc/postgresql/9.1/main/pg_hba.conf

# Install Ruby
RUN \
  apt-get install build-essential libffi-dev libreadline-dev libyaml-dev zlib1g-dev ;\
  apt-get install libsqlite3-dev libmysqlclient-dev libmemcached-dev libmagickwand-dev ;\
  apt-get install libev-dev libevent-dev ;\
  apt-get install libssl-dev libcurl4-openssl-dev curl openssl ca-certificates ;\
  apt-get install libxml2 libxml2-dev libxslt1-dev ;\
  ruby_build_url="https://github.com/sstephenson/ruby-build/archive/v$RUBY_BUILD_VERSION.tar.gz" ;\
  wget -O - $ruby_build_url | tar -C /usr/local/src -zxv ;\
  cd /usr/local/src/ruby-build-$RUBY_BUILD_VERSION && sh install.sh

RUN \
  ruby-build -v $RUBY_VERSION /usr/local/lib/$RUBY_VERSION ;\
  echo "gem: --no-rdoc --no-ri" > /root/.gemrc
# End install Ruby

# Install Default Gems
RUN \
  gem install bundler ;
# END RUN

# Install Node
RUN \
  curl https://raw.github.com/isaacs/nave/master/nave.sh -o /root/nave.sh &&\
  chmod +x /root/nave.sh &&\
  /root/nave.sh usemain 0.8.26

# "Mount" the current directory in /var/apps/action.io
ADD ./ /var/apps/action.io

RUN git submodule init
RUN git submodule update
RUN bundle install
