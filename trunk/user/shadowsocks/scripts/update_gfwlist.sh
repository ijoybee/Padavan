#!/bin/sh

set -e -o pipefail
[ "$1" != "force" ] && [ "$(nvram get ss_update_gfwlist)" != "1" ] && exit 0
#GFWLIST_URL="$(nvram get ss_gfwlist_url)"
logger -st "gfwlist" "Starting update..."
# 1. 从 NVRAM 中读取前端网页保存的自定义地址
CUSTOM_GFWLIST_URL="$(nvram get ss_gfwlist_url)"
# 2. 判断用户是否填写了自定义地址
if [ -n "$CUSTOM_GFWLIST_URL" ]; then
    # 如果填写了，就用自定义的
    GFWLIST_URL="$CUSTOM_GFWLIST_URL"
    logger -st "gfwlist" "使用自定义 gfwlist 地址..."
else
    # 如果没填（为空），则回退使用默认的备用地址
    GFWLIST_URL="https://fastly.jsdelivr.net/gh/Loukky/gfwlist-by-loukky@master/gfwlist.txt"
    logger -st "gfwlist" "使用默认 gfwlist 地址..."
fi
# 3. 执行 curl 下载，将原本写死的地址替换为变量 "$GFWLIST_URL"
curl -k -s -o /tmp/gfwlist_list_origin.conf --connect-timeout 15 --retry 5 "$GFWLIST_URL"
lua /etc_ro/ss/gfwupdate.lua
count=`awk '{print NR}' /tmp/gfwlist_list.conf|tail -n1`
if [ $count -gt 1000 ]; then
rm -f /etc/storage/gfwlist/gfwlist_listnew.conf
cp -r /tmp/gfwlist_list.conf /etc/storage/gfwlist/gfwlist_listnew.conf
mtd_storage.sh save >/dev/null 2>&1
mkdir -p /etc/storage/gfwlist/
logger -st "gfwlist" "Update done"
if [ $(nvram get ss_enable) = 1 ]; then
lua /etc_ro/ss/gfwcreate.lua
logger -st "SS" "重启ShadowSocksR Plus+..."
/usr/bin/shadowsocks.sh stop
/usr/bin/shadowsocks.sh start
fi
else
logger -st "gfwlist" "列表下载失败,请重试！"
fi
rm -f /tmp/gfwlist_list_origin.conf
rm -f /tmp/gfwlist_list.conf

