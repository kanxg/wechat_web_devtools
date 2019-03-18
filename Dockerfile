# canyoutle/wxdt
# 开发者工具各版本docker image
# see also bin/build_docker.sh
# Usage:
# docker run -P -p 6080:80 --mount type=bind,source=$PWD,target=/weapps canyoutle/wxdt

FROM dorowu/ubuntu-desktop-lxde-vnc:bionic

RUN sed -i 's#http://\(archive\|security\).ubuntu.com/#http://mirrors.aliyun.com/#' /etc/apt/sources.list \
  && cat /etc/apt/sources.list
RUN apt-get update \
  && apt-get install -y --no-install-recommends --allow-unauthenticated \
    wget \
    gpg-agent \
    dbus \
    libgconf-2-4 \
    build-essential \
    ca-certificates \
    openssl \
    gnupg2

# install wine and config wine
RUN dpkg --add-architecture i386 \
  && wget -nc https://dl.winehq.org/wine-builds/winehq.key \
  && apt-key add winehq.key \
  && apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' \
  && apt-get update \
  && apt-get install -y --no-install-recommends --allow-unauthenticated winehq-stable

ENV LANG C.UTF-8
ENV DISPLAY :1.0
ENV HOME /root
ENV PATH="/wxdt/bin:${PATH}"
RUN echo "Asia/Shanghai" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

COPY . /wxdt

# 配置wine
RUN env LC_ALL=zh_CN.UTF-8 wine /wxdt/package.nw/js/vendor/wcsc.exe

# 将开发者工具加入supervisord
RUN echo "\n\
[program:wxdt]\n\
priority=25\n\
directory=/wxdt/bin/\n\
command=bash wxdt start\n\
stderr_logfile=/var/log/wxdt.err.log\n\
stdout_logfile=/var/log/wxdt.out.log\n\
" >> /etc/supervisor/conf.d/supervisord.conf

# 将 /startup.sh 转到后台运行
RUN sed -i \
    -e s%'ln -s '%'ln -sf '% \
    /startup.sh

# 安装开发者工具，然后删除下载的文件
RUN update_nwjs.sh \
    && rm -rf /tmp/wxdt_xsp

RUN docker-entrypoint.sh wxdt install \
    && rm -rf /root/.config/wechat_web_devtools/Default/.ide

# VOLUME /root/.config/wechat_web_devtools
ENTRYPOINT [ "/wxdt/bin/docker-entrypoint.sh" ]
