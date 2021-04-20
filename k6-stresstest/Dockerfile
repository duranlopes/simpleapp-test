FROM ubuntu:latest
RUN apt-get update -y && apt-get install -y gnupg wget git vim iputils-ping

COPY . /app
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61 && \
echo "deb https://dl.bintray.com/loadimpact/deb stable main" | tee -a /etc/apt/sources.list && \
wget -q -O - https://bintray.com/user/downloadSubjectPublicKey?username=bintray | apt-key add -
RUN apt-get update -y && apt-get install -y k6
