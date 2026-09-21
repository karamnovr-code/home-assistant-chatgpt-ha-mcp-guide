#!/usr/bin/env bash
set -euo pipefail

cd /data

ln -sfn /opt/mbplugin /data/mbplugin

if [[ ! -f /data/mbplugin.ini || ! -f /data/phones.ini ]]; then
  python /opt/mbplugin/plugin/util.py init
fi

python /opt/mbplugin/plugin/util.py set ini/HttpServer/host=0.0.0.0
python /opt/mbplugin/plugin/util.py set ini/HttpServer/port=19777

exec python /opt/mbplugin/plugin/httpserver_mobile.py --cmd start
