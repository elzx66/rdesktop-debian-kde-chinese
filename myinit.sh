#!/bin/bash

# 检查参数数量
if [ $# -ne 2 ]; then
    echo "用法: $0 <HOME_DIR> <PYCHARM_VERSION>"
    exit 1
fi

# 获取参数
HOME="$1"
PYCHARM_VERSION="$2"

# 检查桌面目录是否存在，如果不存在则创建
if [ ! -d "${HOME}/Desktop" ]; then
    mkdir -p "${HOME}/Desktop"
fi

# 复制 Chromium 和 WPS Office 的桌面快捷方式到桌面
cp /usr/share/applications/chromium.desktop "${HOME}/Desktop/"
cp /usr/share/applications/wps-office-prometheus.desktop "${HOME}/Desktop/"

# 创建 PyCharm 的桌面快捷方式
cat << EOF > ${HOME}/Desktop/pycharm.desktop
[Desktop Entry]
Name=PyCharm Community Edition
Comment=Python IDE
Exec=/opt/pycharm-community-${PYCHARM_VERSION}/bin/pycharm.sh
Icon=/opt/pycharm-community-${PYCHARM_VERSION}/bin/pycharm.svg
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

# 初始化一下 fcitx 输入法程序，下面的代码也不行，貌似docker版本有bug。
# /bin/bash -c "fcitx-autostart &"
echo "自定义脚本myinit.sh完成"
