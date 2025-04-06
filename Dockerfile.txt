FROM ghcr.io/linuxserver/baseimage-rdesktop:debianbookworm

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

####### my added code ########
#设置中文变量
ENV LC_ALL=zh_CN.UTF-8
# 设置输入法环境变量
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV GTK_IM_MODULE=fcitx

# 安装中文字体、 Fcitx 输入法框架和中文输入法。进入系统要手动激活一下：在应用程序搜索栏搜索"input"，在搜索结果中点击"Fcitx"即可，不是“Fcitx配置”
RUN \
  echo "**** install chinese fonts and input ****" && \
  apt-get update && apt-get install -y \
    fonts-noto-cjk \
    fcitx \
    fcitx-pinyin \
    fcitx-config-gtk
    
RUN \
  echo "**** Install tools packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  wget tar unzip && \
  echo "**** update  sources; write to sources.list.d ****" && \
  echo 'Enabled: yes\nTypes: deb\nURIs: http://repo.debiancn.org/\nSuites: \
  bookworm\nComponents: main\nSigned-By: /usr/share/keyrings/debiancn-keyring.gpg' > /etc/apt/sources.list.d/debiancn.sources && \
  echo "**** Install debiancn keyring ****" && \
  wget https://repo.debiancn.org/pool/main/d/debiancn-keyring/debiancn-keyring_0~20250123_all.deb -O /tmp/debiancn-keyring.deb && \
  apt install -y /tmp/debiancn-keyring.deb && \
  apt-get update && \
  rm /tmp/debiancn-keyring.deb

# 安装 WPS Office 可能需要的额外依赖以及wps
RUN \
  echo "**** Install WPS ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  libglib2.0-0 libxrender1 libxext6 libxtst6 libnss3 libasound2 xdg-utils && \
  apt-get update && apt-get install -y wps-office || { apt-get -f install -y; exit 1; } && \
  echo "**** Install WPS Fonts****" && \
  cd /tmp && \
  mkdir /tmp/fonts && \
  wget -O /tmp/fonts.tar.gz -L "https://github.com/BannedPatriot/ttf-wps-fonts/archive/refs/heads/master.tar.gz" && \
  tar xf /tmp/fonts.tar.gz -C /tmp/fonts/ --strip-components=1 && \
  cd /tmp/fonts && \
  bash install.sh

# 下载并安装 PyCharm 社区版，使用手动指定的下载地址
ARG PYCHARM_VERSION=2024.3.4
ARG PYCHARM_URL=https://download.jetbrains.com/python/pycharm-community-${PYCHARM_VERSION}.tar.gz
RUN echo "**** install pycharm community ****" \
    && wget -O pycharm.tar.gz $PYCHARM_URL \
    && tar -xzf pycharm.tar.gz -C /opt \
    && rm pycharm.tar.gz \
    && ln -s /opt/pycharm-community-*/bin/pycharm.sh /usr/local/bin/pycharm
####### my added code ########

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    chromium \
    chromium-l10n \
    dolphin \
    gwenview \
    kde-config-gtk-style \
    kdialog \
    kfind \
    khotkeys \
    kio-extras \
    knewstuff-dialog \
    konsole \
    ksystemstats \
    kwin-addons \
    kwin-x11 \
    kwrite \
    plasma-desktop \
    plasma-workspace \
    qml-module-qt-labs-platform \
    systemsettings && \
  echo "**** application tweaks ****" && \
  sed -i \
    's#^Exec=.*#Exec=/usr/local/bin/wrapped-chromium#g' \
    /usr/share/applications/chromium.desktop && \
  echo "**** kde tweaks ****" && \
  sed -i \
    's/applications:org.kde.discover.desktop,/applications:org.kde.konsole.desktop,/g' \
    /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# #### my added code ####
# #创建桌面快捷方式：
# RUN \
#   if [ ! -d "${HOME}/Desktop" ]; then \
#     mkdir -p ${HOME}/Desktop; \
#   fi && \
#   #cp /usr/share/applications/im-config.desktop ${HOME}/Desktop/ &&\
#   cp /usr/share/applications/chromium.desktop ${HOME}/Desktop/ &&\
#   cp /usr/share/applications/wps-office-prometheus.desktop ${HOME}/Desktop/ &&\
#   echo "[Desktop Entry]\n\
# Name=PyCharm Community Edition\n\
# Comment=Python IDE\n\
# Exec=/opt/pycharm-community-${PYCHARM_VERSION}/bin/pycharm.sh\n\
# Icon=/opt/pycharm-community-${PYCHARM_VERSION}/bin/pycharm.svg\n\
# Terminal=false\n\
# Type=Application\n\
# Categories=Development;IDE;" > /usr/share/applications/pycharm.desktop
# #### my added code ####

# add local files
COPY /root /

# ports and volumes
EXPOSE 3389

VOLUME /config

# 给脚本添加执行权限
COPY /root/defaults/myinit.sh /myinit.sh
RUN chmod +x /myinit.sh
# CMD ["/defaults/myinit.sh","${HOME}","${PYCHARM_VERSION}"]
# ENTRYPOINT ["/defaults/myinit.sh && /init"]
# 在 init 脚本的 exec 命令前插入执行 myinit.sh 并传递变量的命令
RUN sed -i "/exec s6-overlay-suexec/i \/myinit.sh \"$HOME\" \"$PYCHARM_VERSION\"" /init
