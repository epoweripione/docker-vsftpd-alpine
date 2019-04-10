FROM alpine:latest

LABEL Maintainer="Ansley Leung" \
      Description="vsftpd Docker image based on Alpine. Supports passive mode and virtual users." \
      License="MIT License" \
      Version="1.15.10"

# if you want use APK mirror then uncomment, modify the mirror address to which you favor
# RUN sed -i 's|http://dl-cdn.alpinelinux.org|https://mirrors.aliyun.com|g' /etc/apk/repositories

RUN apk update \
    && apk upgrade \
    && apk add -U shadow build-base linux-pam-dev unzip vsftpd openssl

# make pam_pwdfile.so
COPY libpam-pwdfile.zip /tmp/

RUN unzip -q /tmp/libpam-pwdfile.zip -d /tmp/ \
    && cd /tmp/libpam-pwdfile \
    && make install \
    && rm -rf /tmp/libpam-pwdfile \
    && rm -f /tmp/libpam-pwdfile.zip

# some clean job
RUN apk del build-base linux-pam-dev unzip \
    && rm -rf /var/cache/apk/*

ENV FTP_USER **String**
ENV FTP_PASS **Random**
ENV PASV_ADDRESS **IPv4**
ENV PASV_MIN_PORT 21100
ENV PASV_MAX_PORT 21110

RUN echo -e "\n## more option" >> /etc/vsftpd/vsftpd.conf \
    && echo "ftpd_banner=Welcome to FTP Server" >> /etc/vsftpd/vsftpd.conf \
    && echo "dirmessage_enable=YES" >> /etc/vsftpd/vsftpd.conf \
    && echo "max_clients=10" >> /etc/vsftpd/vsftpd.conf \
    && echo "max_per_ip=5" >> /etc/vsftpd/vsftpd.conf \
    && echo "local_umask=022" >> /etc/vsftpd/vsftpd.conf \
    && echo "passwd_chroot_enable=yes" >> /etc/vsftpd/vsftpd.conf \
    && echo "listen_ipv6=NO" >> /etc/vsftpd/vsftpd.conf

COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd.sh /usr/sbin/
COPY vsftpd_virtual /etc/pam.d/

RUN chmod +x /usr/sbin/vsftpd.sh \
    && mkdir -p /var/log/vsftpd/ \
    && mkdir -p /etc/vsftpd/vsftpd_user_conf/ \
    && mkdir -p /var/mail/ \
    && useradd vsftpd -s /sbin/nologin \
    && useradd virtual -m -d /home/ftp/ -s /sbin/nologin \
    && chown -R virtual:virtual /home/ftp/

VOLUME /home/ftp
VOLUME /var/log/vsftpd

EXPOSE 20 21 21100-21110

CMD ["/usr/sbin/vsftpd.sh"]
