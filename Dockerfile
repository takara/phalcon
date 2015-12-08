FROM debian:7.9

MAINTAINER taka2063

WORKDIR /root/

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install wget net-tools git make php5 apache2 \
	php5-dev php5-mysql vim curl chkconfig gcc libpcre3-dev 

# phalconインストール
RUN \
	git clone --depth=1 https://github.com/phalcon/cphalcon.git -b phalcon-v2.0.9 && \
	cd /root/cphalcon/build/64bits && \
	phpize && ./configure CFLAS="-02 -g" && make install && \
	rm -rf /root/cphalcon

# phalcon設定
COPY asset/phalcon.ini /etc/php5/mods-available/
RUN ln -s /etc/php5/mods-available/phalcon.ini /etc/php5/conf.d/20-phalcon.ini

# composer
RUN curl -s http://getcomposer.org/installer | php
RUN chmod +x composer.phar
RUN mv composer.phar /usr/local/bin/composer

# box
WORKDIR /root/
RUN curl -LSs https://box-project.github.io/box2/installer.php | php
RUN mv box.phar /usr/local/bin/box

# phalcon devtools
RUN \
	git clone https://github.com/phalcon/phalcon-devtools.git && \
	cd /root/phalcon-devtools && \
	composer install && \
	sed -i -e '8,18d' box.json && \
	echo "phar.readonly = Off" >> /etc/php5/cli/php.ini && \
	box build && \
	mv phalcon.phar /usr/local/bin/phalcon && \
	chmod +x /usr/local/bin/phalcon && \
	cd /root && rm -rf phalcon-devtools  

# 設定ファイルコピー
COPY asset/apache2.conf /etc/apache2/
COPY asset/default /etc/apache2/sites-available/
COPY asset/php.ini /etc/php5/apache2/
RUN a2enmod rewrite
RUN mkdir -p /var/log/phalcon && chown www-data.www-data /var/log/phalcon
ENV DEBIAN_FRONTEND dialog

# ttyコメントアウト
RUN sed -i -e 's/^\([1-6]:.\+\)/#\1/g' /etc/inittab

EXPOSE 80

WORKDIR /var/www/

CMD ["/sbin/init", "3"]
