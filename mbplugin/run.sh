#!/usr/bin/env bash
set -euo pipefail

cd /data

# Keep runtime code under /data so MBPlugin resolves its configuration,
# database and browser state to Home Assistant's persistent add-on storage.
rm -rf /data/mbplugin
cp -a /opt/mbplugin /data/mbplugin

if [[ ! -f /data/mbplugin.ini || ! -f /data/phones.ini ]]; then
  python /data/mbplugin/plugin/util.py init
fi

python /data/mbplugin/plugin/util.py set ini/HttpServer/host=0.0.0.0
python /data/mbplugin/plugin/util.py set ini/HttpServer/port=19777

exec python /data/mbplugin/plugin/httpserver_mobile.py --cmd start
