FROM haproxy:latest

RUN mkdir -p /etc/haproxy/errors

RUN touch /etc/haproxy/errors/400.http
RUN touch /etc/haproxy/errors/403.http
RUN touch /etc/haproxy/errors/408.http
RUN touch /etc/haproxy/errors/500.http
RUN touch /etc/haproxy/errors/502.http
RUN touch /etc/haproxy/errors/503.http
RUN touch /etc/haproxy/errors/504.http

RUN chmod -R 777 /etc/haproxy/errors

VOLUME /etc/haproxy/errors

RUN mkdir -p /run/haproxy

RUN apt-get update && apt-get install -y socat tcpdump strace --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

EXPOSE 80
EXPOSE 4691
