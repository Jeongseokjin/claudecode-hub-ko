#!/bin/bash
# ccstatusline 렌더러 + orca 사용량 전달 사슬.
# Claude Code 는 세션 JSON 을 stdin 으로 한 번만 준다. 소비자가 둘이라 복제한다.
payload=$(cat)

# 이전 상태줄: rate_limits payload 를 Orca 앱으로 넘긴다. 렌더링을 늦추지 않게 뒤로 보낸다.
if [ -x "$HOME/.orca/agent-hooks/claude-statusline.sh" ]; then
  printf '%s' "$payload" | /bin/sh "$HOME/.orca/agent-hooks/claude-statusline.sh" >/dev/null 2>&1 &
fi

# 터미널 실폭. stdout 이 파이프라 COLUMNS 가 안 물려 내려온다.
cols=${COLUMNS:-}
case "$cols" in ""|*[!0-9]*) cols=$(stty size 2>/dev/null </dev/tty | awk '{print $2}');; esac
case "$cols" in ""|*[!0-9]*) cols=120;; esac
export COLUMNS=$(( cols > 4 ? cols - 4 : 1 ))

NODE=/Users/seokjin/.nvm/versions/node/v24.14.1/bin/node
[ -x "$NODE" ] || NODE=$(command -v node 2>/dev/null) || exit 0
CCS=/Users/seokjin/.nvm/versions/node/v24.14.1/lib/node_modules/ccstatusline/dist/ccstatusline.js
[ -f "$CCS" ] || exit 0

# NODE_OPTIONS 를 물려받지 않는다. 바깥에서 --require 로 임시 파일을 preload 하도록 걸어 두는
# 도구가 있는데, 그 임시 파일은 OS 가 청소해 간다. 사라진 뒤에는 node 가 시작조차 못 하고,
# 그러면 상태줄은 오류 없이 그냥 안 보인다 - 여기서 끊어 두면 바깥 설정과 무관하게 뜬다.
printf '%s' "$payload" | env -u NODE_OPTIONS "$NODE" "$CCS"
