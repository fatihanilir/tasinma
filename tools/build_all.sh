#!/usr/bin/env bash
# Statik siteyi ve /hesapla altındaki Flutter uygulamasını public/ içine derler.
# Kullanım: tools/build_all.sh && firebase deploy --only hosting
set -euo pipefail
cd "$(dirname "$0")/.."

flutter build web --release --base-href /hesapla/ --pwa-strategy=none
python3 tools/build_site.py
cp -R build/web public/hesapla
echo "Hazır: public/ (site) + public/hesapla/ (uygulama)"
