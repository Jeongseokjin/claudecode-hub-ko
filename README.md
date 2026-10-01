# claudecode-hub-ko

**Claude Code 상태줄 설정.** ccstatusline 의 기본값을 고쳐 쓴 것이고, 언어 10개가 들어 있다.

도구를 고치지 않는다. 설정 파일 하나로 끝난다.

---

## 무엇이 달라지나

설치 직후 ccstatusline 은 이렇게 나온다.

```
Model: Opus 5 | Ctx: 669.4k | ⎇ main | (+0,-0)
```

이 설정을 넣으면 이렇게 나온다.

```
[Opus 5] │ loginexio-api git:(main)
컨텍스트 ▓▓▓▓▓▓░░░░ 62% │ 사용량 ▓░░░░░░░░░ 9% │ 주간 ░░░░░░░░░░ 2% │ Fable ░░░░░░░░░░ 0%
PR #853 │ CI ✓3 │ 캐시 87%
```

셋째 줄은 볼 것이 있을 때만 나온다. PR 도 CI 도 캐시도 없으면 줄이 통째로 사라진다.

---

## 무엇을 왜 고쳤나

고친 자리마다 이유가 있다. 아홉 가지다.

### 1. 컨텍스트를 토큰 수에서 퍼센트로

기본값은 `Ctx: 669.4k` 라고 토큰 수를 준다. 그런데 **그게 한도의 몇 퍼센트인지는 안 알려 준다.**
모델마다 한도가 다르니 669.4k 만 봐서는 여유가 있는지 알 수 없다. 퍼센트로 바꾸고 막대를 붙였다.

```jsonc
{ "type": "context-percentage", "metadata": { "display": "slider" } }
```

### 2. 사용량과 주간 한도를 더했다

기본값에는 **사용량이 아예 없다.** 5시간 창과 주간 창을 더했다. 한도에 걸려서 멈추기 전에
미리 보이는 편이 낫다.

### 3. 모델별 주간 한도는 Fable 만 넣었다

ccstatusline 에는 모델별 주간 한도 위젯이 셋 있다.

```jsonc
{ "type": "weekly-opus-usage" }
{ "type": "weekly-sonnet-usage" }
{ "type": "fable-weekly-usage" }
```

셋 다 넣어 봤더니 전체 주간이 4% 인데 **셋 다 `0%`** 로 나왔다. 캐시
(`~/.cache/ccstatusline/usage.json`)를 열어 봤다.

```jsonc
{
  "weeklyUsage": 4,
  "weeklyOpusUsage": 0,     // weeklyOpusResetAt 이 없다
  "weeklySonnetUsage": 0,   // weeklySonnetResetAt 이 없다
  "fableUsage": 0,
  "fableResetAt": "2026-10-07T06:00:00+00:00"   // 이것만 있다
}
```

**초기화 시각이 있고 없고가 갈린다.** ccstatusline 은 모델별 항목을 찾으면 사용량과 초기화
시각을 같이 저장한다. Fable 은 시각이 있으니 항목을 찾은 것이고 진짜 0% 다. Opus·Sonnet 은
시각이 없으니 **항목을 못 찾아서 0 으로 채운 것**이다. Opus 사용분은 전체 주간 4% 안에
들어가 있다.

**그래서 Fable 만 남기고 Opus·Sonnet 은 뺐다.** Fable 의 `0%` 는 「이번 주에 안 썼다」는
사실이라 보여 줄 값이 있다. Opus 의 `0%` 는 「많이 남았다」로 읽히는데 사실이 아니다 —
Opus 사용분은 전체 주간 안에 들어가 있다. 상태줄은 흘깃 보는 물건이라
**틀린 숫자를 보여 주느니 안 보여 주는 편이 낫다.**

`hide` 로 숨기는 것도 안 된다. 이 위젯들에는 숨김 규칙 자체가 등록돼 있지 않아서
`"hide": "no-data"` 를 줘도 그대로 `0.0%` 가 나온다.

**Opus·Sonnet 을 쓰고 싶으면** 위 두 줄을 둘째 줄에 넣으면 된다. 먼저 캐시 파일을 열어
`weeklyOpusResetAt` 이 **있는지** 보면 그 계정에 값이 오는지 알 수 있다. 없으면 또 `0%` 가
나온다.

### 4. 이름표를 번역했다

ccstatusline 위젯은 `Ctx Used:` 처럼 영어 이름표를 스스로 붙인다. 그 이름표를 떼고
원하는 말을 앞에 넣는다.

```jsonc
// rawValue 가 위젯의 이름표를 뗀다
{ "type": "context-percentage", "rawValue": true }    // "Ctx Used: 62%" → "62%"

// 그 앞에 custom-text 로 원하는 말을 넣는다
{ "type": "custom-text", "customText": "컨텍스트 " }
```

이 방식이라 도구를 고칠 필요가 없고, 언어를 바꾸는 것이 파일 하나 갈아 끼우는 일이 된다.

### 5. 값이 없을 때 이름표도 같이 숨긴다

4번을 그냥 쓰면 문제가 생긴다. PR 이 없을 때 값은 사라지는데 **`PR` 이라는 글자만 남는다.**
이름표를 값에 붙여 두면 같이 사라진다.

```jsonc
{
  "type": "custom-text", "customText": "PR ",
  "merge": true,
  "metadata": { "hide": "merge-target-hidden" }
}
```

### 6. PR·CI·캐시를 셋째 줄로 내렸다

한 줄에 다 넣으면 터미널을 넘긴다. 이 셋은 **늘 있는 값이 아니라** 있을 때만 의미가 있어서
따로 뺐다. 셋 다 없으면 줄이 아예 안 그려진다.

### 7. 소수점을 뗐다

`62.0%` 의 `.0` 은 자리만 먹는다. 상태줄은 좁다.

```jsonc
{ "numberFormat": { "style": "whole" } }
```

### 8. 색을 넣었다

기본값은 색이 거의 없어서 어디가 값이고 어디가 이름표인지 구분이 안 된다. 값은 밝게,
구분자(`│`·`·`)는 어둡게 둬서 값이 먼저 눈에 들어오게 했다.

### 9. 경로 대신 레포 이름을 쓴다

`current-working-dir` 은 전체 경로나 `.../이름` 을 준다. `git-root-dir` 은 레포 이름만 준다.

---

## 쓰는 법

### 깔기

```bash
git clone https://github.com/Jeongseokjin/claudecode-hub-ko.git
cd claudecode-hub-ko
./install.sh
```

Claude Code 를 다시 켜면 보인다.

설치 스크립트가 하는 일은 넷이다.

1. `ccstatusline` 이 없으면 깐다 (`npm install -g ccstatusline@2.2.30`)
2. 고른 언어의 설정을 `~/.config/ccstatusline/settings.json` 에 넣는다
3. 사슬 스크립트를 `~/.claude/statusline.sh` 에 넣고 `node` 경로를 이 기계 것으로 박는다
4. `~/.claude/settings.json` 의 `statusLine` 한 줄만 바꾼다

**있던 파일은 덮어쓰기 전에 시각을 붙여 남긴다.** `settings.json` 의 다른 칸은 안 건드린다.

### 언어 고르기

```bash
./install.sh --list     # 고를 수 있는 언어를 본다
./install.sh ja         # 일본어로 깐다
```

| | | | | |
|---|---|---|---|---|
| `ko` 한국어 | `en` English | `ja` 日本語 | `zh-Hans` 简体 | `zh-Hant` 繁體 |
| `es` Español | `fr` Français | `de` Deutsch | `pt-BR` Português | `ru` Русский |

```
ko        컨텍스트 ▓▓▓▓▓▓░░░░ 62% │ 사용량 ▓░░░░░░░░░ 9% │ 주간 ░░░░░░░░░░ 2%
ja        コンテキスト ▓▓▓▓▓▓░░░░ 62% │ 使用量 ▓░░░░░░░░░ 9% │ 週間 ░░░░░░░░░░ 2%
zh-Hans   上下文 ▓▓▓▓▓▓░░░░ 62% │ 用量 ▓░░░░░░░░░ 9% │ 本周 ░░░░░░░░░░ 2%
ru        Контекст ▓▓▓▓▓▓░░░░ 62% │ Расход ▓░░░░░░░░░ 9% │ Неделя ░░░░░░░░░░ 2%
```

색·막대·순서는 전부 같다. 이름표만 다르다.

### 고치기

`~/.config/ccstatusline/settings.json` 을 열면 된다. `lines` 배열 하나가 화면 한 줄이고,
그 안의 객체 하나가 위젯 하나다.

| 하고 싶은 것 | 어떻게 |
|---|---|
| 막대 없애기 | 그 위젯의 `metadata.display` 를 지운다 |
| 소수점 보기 | `numberFormat` 을 지운다 (`62%` → `62.0%`) |
| 색 바꾸기 | `"color": "hex:FF79C6"` |
| Opus·Sonnet 더 보기 | 둘째 줄에 `weekly-opus-usage` 를 넣는다 ([먼저 읽을 것](#3-모델별-주간-한도는-fable-만-넣었다)) |
| 줄 더하기 | `lines` 에 배열을 하나 더 넣는다 |
| 위젯 목록 보기 | `ccstatusline` 을 그냥 실행하면 고르는 화면이 뜬다 |

고치면 바로 반영된다. Claude Code 를 다시 켤 필요 없다.

### 되돌리기

설치할 때 남긴 백업을 덮어쓰면 된다.

```bash
ls ~/.config/ccstatusline/settings.json.bak-*
cp ~/.config/ccstatusline/settings.json.bak-<시각> ~/.config/ccstatusline/settings.json
```

ccstatusline 기본값으로 아주 돌아가려면 설정 파일을 지운다. 도구가 다음 실행 때 기본값을
다시 만든다.

```bash
rm ~/.config/ccstatusline/settings.json
```

상태줄 자체를 끄려면 `~/.claude/settings.json` 에서 `statusLine` 을 지운다.

---

## 사슬 스크립트

상태줄을 바로 부르지 않고 `~/.claude/statusline.sh` 를 한 번 거친다. 이유가 셋이다.

**`NODE_OPTIONS` 를 끊는다.** 이것 때문에 넣었다. 바깥에서 `--require` 로 임시 파일을
preload 하게 걸어 두는 도구가 있는데, 그 임시 파일을 OS 가 청소해 간다. 사라진 뒤에는
node 가 시작조차 못 하고, 그러면 **상태줄이 오류 없이 그냥 안 보인다.** 오류 메시지가 없어서
원인을 찾기가 아주 어렵다.

**`COLUMNS` 를 `stty` 로 실측한다.** 상태줄은 stdout 이 파이프로 물려 있어서 터미널 폭이
안 내려온다. 안 재면 줄바꿈 계산이 틀려 화면이 접힌다.

**느린 일은 뒤로 보낸다.** 렌더링을 늦추지 않는다.

---

## 걸렸던 것들

설정을 만들면서 실제로 막혔던 자리다. 전부 **오류 없이 조용히 안 되는** 종류라 적어 둔다.

**색은 `hex:RRGGBB` 형식이다.**

```jsonc
{ "color": "hex:39FF14" }   // 된다
{ "color": "#39FF14" }      // 안 된다. 굵게만 들어가고 색이 안 나간다
```

**`colorLevel` 이 3 이어야 hex 가 그대로 나간다.** 2 면 가까운 256색으로 뭉개진다.

**Fable 위젯만 이름 순서가 다르다.**

```
weekly-opus-usage      맞다
weekly-sonnet-usage    맞다
weekly-fable-usage     이런 건 없다
fable-weekly-usage     이게 맞다
```

**설정은 `$HOME/.config/ccstatusline/` 에 둬야 한다.** ccstatusline 은 `XDG_CONFIG_HOME` 을
보지 않는다. XDG 를 따라 다른 데 두면 파일은 잘 놓이는데 화면이 안 바뀐다.

**막대 문자는 못 바꾼다.** `slider` 는 `▓░`(폭 10), `progress` 는 `[█░]`(대괄호 포함).
둘 중에 고르는 것뿐이다. 여기서는 대괄호가 없는 `slider` 를 쓴다.

---

## 들어 있는 것

```
claudecode-hub-ko/
├── install.sh                    깔고 · 언어 고르고 · 백업까지
└── statusline/
    ├── statusline.sh             사슬 스크립트
    └── locales/                  언어 10개
        ├── ko.json  en.json  ja.json
        ├── zh-Hans.json  zh-Hant.json
        └── es.json  fr.json  de.json  pt-BR.json  ru.json
```

## 언어 더하기

`statusline/locales/` 의 아무 파일이나 복사해서 **이름표 일곱 개만** 바꾸면 된다.
`custom-text` 위젯은 열하나인데 그중 넷(`[`·`] │ `·` git:(`·`)`)은 뼈대라 그대로 둔다.
색·막대·순서도 건드릴 필요 없다. PR 환영.

---

[ccstatusline](https://github.com/sirmalloc/ccstatusline) 설정이다 · MIT
