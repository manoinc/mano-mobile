#!/usr/bin/env bash
# Builds the handbook (Zensical, in Docker) with the Widgetbook catalogue under /widgetbook/.
set -euo pipefail
cd "$(dirname "$0")/.."

image=zensical/zensical:latest
zensical() {
  local tty=()
  [ -t 0 ] && tty=(-it)
  docker run --rm "${tty[@]}" -p 8000:8000 --user "$(id -u):$(id -g)" \
    -v "$PWD":/docs "$image" "$@"
}

catalogue() {
  (cd widgetbook && flutter build web --release --base-href /widgetbook/)
  rm -rf docs/widgetbook
  cp -r widgetbook/build/web docs/widgetbook
}

case "${1:-serve}" in
  catalogue) catalogue ;;
  serve) catalogue && zensical serve --dev-addr=0.0.0.0:8000 ;;
  build) catalogue && zensical build ;;
  *) echo "usage: tools/docs.sh [serve|build|catalogue]" >&2; exit 64 ;;
esac
