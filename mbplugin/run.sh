#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export TZ=Europe/Moscow

if ! command -v chromium >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends chromium ca-certificates curl tzdata fonts-liberation
  rm -rf /var/lib/apt/lists/*
fi

mkdir -p /data /data/home

if [[ ! -f /data/.mbplugin_v1.00.92 ]]; then
  rm -rf /data/mbplugin
  mkdir -p /data/mbplugin
  curl -fsSL https://github.com/artyl/mbplugin/archive/refs/tags/v1.00.92.tar.gz \
    | tar -xz --strip-components=1 -C /data/mbplugin
  touch /data/.mbplugin_v1.00.92
fi

if [[ ! -x /data/venv/bin/python ]]; then
  python -m venv /data/venv
  /data/venv/bin/python -m pip install --no-cache-dir --upgrade pip
  /data/venv/bin/python -m pip install --no-cache-dir -r /data/mbplugin/docker/requirements.txt
fi

cd /data

if [[ ! -f /data/mbplugin.ini || ! -f /data/phones.ini ]]; then
  /data/venv/bin/python /data/mbplugin/plugin/util.py init
fi

/data/venv/bin/python /data/mbplugin/plugin/util.py set ini/HttpServer/host=0.0.0.0
/data/venv/bin/python /data/mbplugin/plugin/util.py set ini/HttpServer/port=19777
/data/venv/bin/python /data/mbplugin/plugin/util.py set ini/Options/use_builtin_browser=0
/data/venv/bin/python /data/mbplugin/plugin/util.py set ini/Options/chrome_executable_path=/usr/bin/chromium
/data/venv/bin/python /data/mbplugin/plugin/util.py set ini/Options/headless_chrome=1

chown -R nobody:nogroup /data
exec su -s /bin/sh nobody -c 'HOME=/data/home /data/venv/bin/python /data/mbplugin/plugin/httpserver_mobile.py --cmd start'
