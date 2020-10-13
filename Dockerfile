FROM centos:7

RUN yum install git wget vim ntpdate zip unzip openssl make zsh update -y
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

RUN yum install epel-release -y

# install nginx & go
RUN yum install nginx  go initscripts -y

# php 7.4
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum -y install yum-utils
RUN yum-config-manager --enable remi-php74
RUN yum install php  php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json php-pecl-redis php-pecl-mongodb php-pgsql -y
RUN yum install -y composer

# swoole 4.5.4
COPY v4.5.4.zip /tmp/
RUN cd /tmp && unzip v4.5.4.zip
RUN cd /tmp/swoole-src-4.5.4/ && \
    phpize && \
    ./configure && \
    make && make install
RUN echo "extension=swoole.so" >> /etc/php.d/80-swoole.ini && echo "swoole.use_shortname = 'Off'" >> /etc/php.d/80-swoole.ini
RUN rm /tmp/v4.5.4.zip && rm -rf /tmp/swoole-src-4.5.4/

#  swoole/ext-postgresql
RUN yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
RUN yum install -y centos-release-scl llvm-toolset-7.0 libpq
RUN yum install -y postgresql12-devel

COPY master.zip /tmp/
RUN cd /tmp && unzip master.zip && cd /tmp/ext-postgresql-master && sed -i 's/#include\ <postgresql\/libpq-fe.h>/#include\ \"\/usr\/pgsql-12\/include\/libpq-fe.h\"/g' swoole_postgresql_coro.h

RUN cd /tmp/ext-postgresql-master && \
    phpize && \
    ./configure && \
    make && make install

# RUN echo "extension=mongodb.so" >> /etc/php.d/60-mongodb.ini
RUN echo "extension=swoole_postgresql.so" >> /etc/php.d/80-swoole.ini

RUN systemctl enable php-fpm
RUN systemctl enable nginx