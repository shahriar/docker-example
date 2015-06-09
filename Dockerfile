FROM    ubuntu:14.04

MAINTAINER shahriar040@gmail.com

RUN apt-get -qq update 
RUN apt-get install -y curl





RUN apt-get install -y python-dev python-setuptools supervisor 
RUN apt-get install -y libffi-dev libssl-dev
RUN easy_install pip
RUN pip install virtualenv
RUN pip install uwsgi
RUN pip install certifi
RUN virtualenv --no-site-packages /opt/ve/djdocker
ADD . /opt/apps/djdocker
ADD docker/supervisor.conf /opt/supervisor.conf
ADD docker/run.sh /usr/local/bin/run
RUN /opt/ve/djdocker/bin/pip install -r /opt/apps/djdocker/requirements.txt
RUN (cd /opt/apps/djdocker && /opt/ve/djdocker/bin/python manage.py syncdb --noinput)
RUN (cd /opt/apps/djdocker && /opt/ve/djdocker/bin/python manage.py collectstatic --noinput)

EXPOSE 8000

CMD ["/bin/sh", "-e", "/usr/local/bin/run"]


RUN apt-get install -y software-properties-common
RUN apt-get install -y python-software-properties
RUN add-apt-repository ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs


RUN \
  cd /tmp && \
  npm install -g npm && \
  printf '\n# Node.js\nexport PATH="node_modules/.bin:$PATH"' >> /root/.bashrc

# App
ADD . /src
# Install app dependencies
RUN cd /src; npm install



# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
RUN apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/*

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.25

RUN echo "deb http://repo.mysql.com/apt/debian/ wheezy mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections \
	&& apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}"* && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql

# comment out a few problematic configuration values
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]





EXPOSE  8080
CMD ["node", "/src/index.js"]















