FROM ubuntu:14.04
MAINTAINER Anton Dimitrov <dimitrov.anton@gmail.com>
RUN useradd -m -d /sandbox -p grader grader && chsh -s /bin/bash grader

RUN apt-get update && apt-get install -y make python2.7 python3 openjdk-7-jre-headless g++ zlib1g-dev libssl-dev

ADD http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz /tmp/
RUN cd /tmp && tar -xzf /tmp/ruby-2.2.2.tar.gz
RUN cd /tmp/ruby-2.2.2/ && ./configure --disable-install-doc && make && make install
RUN rm -rf /tmp/*

RUN gem install rprocfs

WORKDIR /sandbox
