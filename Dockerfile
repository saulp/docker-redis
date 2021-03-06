FROM ubuntu

RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list && \
    apt-get update

#Prevent daemon start during install
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir /var/run/sshd && \
	echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat

#Build tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y automake libtool make

#Redis
RUN wget http://download.redis.io/releases/redis-2.8.0.tar.gz && \
    tar xzf redis-2.8.0.tar.gz && \
    rm redis-2.8.0.tar.gz && \
    cd redis-2.8.0 && \
    make

#twemproxy
RUN git clone https://github.com/twitter/twemproxy.git && \
    cd twemproxy && \
    git checkout tags/v0.2.4 && \
    autoreconf -fvi && \
    ./configure --enable-debug=log && \
    make

#redis-stat
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential ruby1.9.1 ruby1.9.1-dev
RUN gem install redis-stat

#Configuration
ADD . /docker-redis
RUN cd /docker-redis && chmod +x *sh && \
    cp /docker-redis/supervisord-redis.conf /etc/supervisor/conf.d/supervisord-redis.conf && \
    find /redis-2.8.0/src -perm /a+x -type f -exec mv {} /usr/bin \; && \
    find /twemproxy/src -perm /a+x -type f -exec mv {} /usr/bin \;

EXPOSE 22 22222 63790 8888


