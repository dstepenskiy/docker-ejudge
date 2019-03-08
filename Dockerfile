FROM ubuntu:16.04

MAINTAINER Alexey Nurgaliev <atnurgaliev@gmail.com>

ENV LANG="C.UTF-8" \
    DEBIAN_FRONTEND="noninteractive" \
    \
    APACHE_RUN_USER="www-data" \
    APACHE_RUN_GROUP="www-data" \
    APACHE_LOG_DIR="/var/log/apache2" \
    APACHE_PID_FILE="/var/run/apache2.pid" \
    APACHE_RUN_DIR="/var/run/apache2" \
    APACHE_LOCK_DIR="/var/lock/apache2" \
    APACHE_LOG_DIR="/var/log/apache2" \
    \
    EJUDGE_CGI_DIR="/var/www/ejudge/cgi-bin" \
    EJUDGE_HTDOCS_DIR="/var/www/ejudge/htdocs" \
    EJUDGE_BUILD_DIR="/opt/ejudge-build" \
    EJUDGE_HOME_DIR="/home/ejudge" \
    \
    URL_FREEBASIC="http://downloads.sourceforge.net/fbc/FreeBASIC-1.05.0-linux-x86_64.tar.gz?download" \
    URL_EJUDGE="https://github.com/dstepenskiy/ejudge.git"

RUN cd /home &&\
    apt-get update &&\
    apt-get install -y software-properties-common &&\
    add-apt-repository "deb http://repos.lpm.org.ru/kumir2/ubuntu trusty universe" &&\
    apt-get update &&\
    apt-get install -y --allow-unauthenticated \
                       wget locales ncurses-base libncurses-dev libncursesw5 \
                       libncursesw5-dev expat libexpat1 libexpat1-dev \
                       zlib1g-dev libelf-dev mysql-client-5.7 libmysqlclient-dev \
                       g++ gawk apache2 gettext fpc mc openjdk-8-jdk-headless \
                       libcurl4-openssl-dev libzip-dev uuid-dev bison flex \
                       mono-devel mono-runtime mono-vbnc perl python python3 \
                       kumir2-tools git &&\
    \
    locale-gen en_US.UTF-8 ru_RU.UTF-8 &&\
    wget -O freebasic.tar.gz "${URL_FREEBASIC}" &&\
    mkdir /opt/freebasic &&\
    tar -xvf freebasic.tar.gz -C /opt/freebasic --strip-components 1 &&\
    rm freebasic.tar.gz &&\
    cd /opt/freebasic &&\
    ./install.sh -i &&\
    cd /home &&\
    \
    groupadd ejudge &&\
    useradd ejudge -r -s /bin/bash -g ejudge &&\
    mkdir -m 0777 -p "${EJUDGE_CGI_DIR}" "${EJUDGE_HTDOCS_DIR}" "${EJUDGE_BUILD_DIR}" &&\
    \
    git clone "${URL_EJUDGE}" &&\
    cp -R ejudge /opt/ &&\
    rm -r ejudge &&\
    cd /opt/ejudge &&\
    ./configure --prefix="${EJUDGE_BUILD_DIR}" \
                --enable-contests-home-dir="${EJUDGE_HOME_DIR}" \
                --with-httpd-cgi-bin-dir="${EJUDGE_CGI_DIR}" \
                --with-httpd-htdocs-dir="${EJUDGE_HTDOCS_DIR}" \
                --enable-ajax \
                --enable-charset=utf-8 &&\
    make &&\
    make install &&\
    chown -R ejudge:ejudge "${EJUDGE_BUILD_DIR}" &&\
    \
    a2enmod cgi &&\
    rm /etc/apache2/sites-enabled/* &&\
    \
    ln -s /usr/bin/kumir2-bc /usr/local/bin/kumir2-bc &&\
    ln -s /usr/bin/kumir2-run /usr/local/bin/kumir2-run &&\
    rm /bin/sh &&\
    ln -s /bin/bash /bin/sh

ADD apache/ejudge.conf /etc/apache2/sites-enabled/ejudge.conf
ADD scripts /opt/scripts

EXPOSE 80

VOLUME /home/ejudge

CMD ["/bin/bash", "/opt/scripts/run.sh"]
