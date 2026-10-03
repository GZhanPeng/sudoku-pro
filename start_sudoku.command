#!/bin/zsh

set -e

SCRIPT_DIR="${0:A:h}"
FLUTTER_BIN="/Users/guo/.local/share/flutter/bin/flutter"
PYTHON_BIN="/usr/bin/python3"
PORT="8787"
APP_URL="http://127.0.0.1:$PORT"

cd "$SCRIPT_DIR"

NEEDS_BUILD=false
if [[ ! -f "build/web/main.dart.js" ]]; then
  NEEDS_BUILD=true
elif [[ -n "$(/usr/bin/find lib web assets -type f -newer build/web/main.dart.js -print -quit)" ||
        pubspec.yaml -nt build/web/main.dart.js ||
        pubspec.lock -nt build/web/main.dart.js ]]; then
  NEEDS_BUILD=true
fi

if [[ "$NEEDS_BUILD" == true ]]; then
  if [[ ! -x "$FLUTTER_BIN" ]]; then
    echo "没有找到 Flutter：$FLUTTER_BIN"
    echo "请按回车关闭窗口。"
    read -r
    exit 1
  fi
  export PUB_HOSTED_URL="https://pub.flutter-io.cn"
  export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
  echo "检测到代码有更新，正在构建网页版……"
  "$FLUTTER_BIN" build web --release --no-web-resources-cdn
fi

if /usr/bin/curl -fsS --max-time 1 "$APP_URL" 2>/dev/null |
  /usr/bin/grep -q '<title>数独助手</title>'; then
  echo "数独助手已经在运行，正在打开……"
  /usr/bin/open -a "Google Chrome" "$APP_URL"
  exit 0
fi

echo "正在打开数独助手：$APP_URL"
echo "使用期间请保持这个终端窗口；按 Control+C 可停止。"
(
  sleep 1
  /usr/bin/open -a "Google Chrome" "$APP_URL"
) &

exec "$PYTHON_BIN" -m http.server "$PORT" --bind 127.0.0.1 --directory build/web
