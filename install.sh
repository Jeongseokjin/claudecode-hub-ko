#!/usr/bin/env bash
# claudecode-hub-ko installer.
#
#   ./install.sh          한국어로 깐다
#   ./install.sh ja       다른 언어로 깐다
#   ./install.sh --list   고를 수 있는 언어를 본다
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOCALES="$HERE/statusline/locales"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# ccstatusline 은 XDG_CONFIG_HOME 을 안 본다. os.homedir() 아래 .config 를 박아 쓴다.
# 여기서 XDG 를 따르면 파일은 엉뚱한 데 놓이고 화면은 안 바뀐다.
CCS_DIR="$HOME/.config/ccstatusline"

list() { ls "$LOCALES" | sed 's/\.json$//' | tr '\n' ' '; echo; }

if [ "${1:-}" = "--list" ]; then list; exit 0; fi
LANG_CODE="${1:-ko}"
SRC="$LOCALES/$LANG_CODE.json"
if [ ! -f "$SRC" ]; then
  echo "그런 언어가 없다: $LANG_CODE" >&2
  printf '고를 수 있는 것: '; list >&2
  exit 1
fi

# 1. ccstatusline. 버전을 박아 둔다 - 위젯 이름과 설정 형식이 판마다 바뀐다.
if ! command -v ccstatusline >/dev/null 2>&1; then
  echo "▸ ccstatusline 을 깐다"
  npm install -g ccstatusline@2.2.30
fi

# 2. 설정. 있던 것은 시각을 붙여 남긴다.
mkdir -p "$CCS_DIR"
if [ -f "$CCS_DIR/settings.json" ]; then
  BAK="$CCS_DIR/settings.json.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CCS_DIR/settings.json" "$BAK"
  echo "▸ 있던 설정을 남겼다: $BAK"
fi
cp "$SRC" "$CCS_DIR/settings.json"
echo "▸ 설정을 넣었다 ($LANG_CODE)"

# 3. 사슬 스크립트. node 경로는 이 기계 것으로 박는다 - 이유는 스크립트 안에 적혀 있다.
mkdir -p "$CLAUDE_DIR"
NODE_BIN=$(command -v node || true)
if [ -z "$NODE_BIN" ]; then echo "node 를 못 찾았다" >&2; exit 1; fi
sed "s|^NODE=.*|NODE=$NODE_BIN|" "$HERE/statusline/statusline.sh" > "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
echo "▸ 사슬 스크립트를 넣었다 (node: $NODE_BIN)"

# 4. settings.json 의 statusLine 한 줄. 다른 칸은 안 건드린다.
python3 - "$CLAUDE_DIR" <<'PY'
import json, os, sys, datetime
d = sys.argv[1]
p = os.path.join(d, 'settings.json')
cfg = {}
if os.path.exists(p):
    with open(p) as f:
        cfg = json.load(f)
    bak = p + '.bak-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    with open(bak, 'w') as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)
    print('▸ 있던 settings.json 을 남겼다:', bak)
cfg['statusLine'] = {'type': 'command', 'command': f'/bin/bash {d}/statusline.sh'}
with open(p, 'w') as f:
    json.dump(cfg, f, ensure_ascii=False, indent=2)
print('▸ statusLine 을 걸었다')
PY

echo
echo "끝났다. Claude Code 를 다시 켜면 보인다."
