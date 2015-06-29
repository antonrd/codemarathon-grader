FROM ubuntu:14.04
MAINTAINER Anton Dimitrov <dimitrov.anton@gmail.com>
RUN useradd -m -d /sandbox -p grader grader && chsh -s /bin/bash grader
RUN apt-get update && apt-get install -y ruby ruby-dev make python2.7 gcj-jdk g++
RUN gem install rprocfs

WORKDIR /sandbox
