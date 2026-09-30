<div align="center">

# claudecode-hub-ko

**Claude Code 상태줄, 읽히게.**

모델 · 레포 · 가지 · 컨텍스트 · 사용량, 그리고 **모델별 주간 한도**까지 한눈에.
10개 언어. 포크 없이 설정 파일 하나로.

</div>

```
[Opus 5] │ loginexio-api git:(main)
컨텍스트 ▓▓▓▓▓▓░░░░ 62% │ 사용량 ▓░░░░░░░░░ 9% │ 주간 ░░░░░░░░░░ 2% │ Opus 41% · Sonnet 12% · Fable 0%
PR #853 │ CI ✓3 │ 캐시 87%
```

셋째 줄은 **볼 것이 있을 때만** 뜬다. PR 도 CI 도 캐시도 없으면 줄이 통째로 사라진다.

---

## 30초면 깔린다

```bash
git clone https://github.com/Jeongseokjin/claudecode-hub-ko.git
cd claudecode-hub-ko
./install.sh          # 한국어
```

Claude Code 를 다시 켜면 보인다. 끝.

```bash
./install.sh ja       # 다른 언어
./install.sh --list   # 고를 수 있는 언어
```

설치 스크립트는 `ccstatusline` 을 깔고, 설정을 넣고, `node` 경로를 이 기계 것으로 박고,
`~/.claude/settings.json` 의 `statusLine` 한 줄만 건드린다. **있던 파일은 시각을 붙여 남긴다.**

## 언어 10개

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

색·막대·순서는 전부 같다. **이름표만 다르다.**

## 왜 이걸 만들었나

Claude Code 상태줄 도구가 둘 있는데 둘 다 반쪽이었다.

**claude-hud** 은 모양이 좋다. 막대도 예쁘고 배치도 낫다. 그런데 **모델별 사용량을 못 본다.**
Claude Code 가 주는 stdin 의 `rate_limits` 에는 `five_hour` 와 `seven_day` 둘뿐이고
`model_scoped` 가 안 온다. Opus 를 얼마나 썼는지, Fable 이 남았는지 알 길이 없다.

**ccstatusline** 은 API 를 직접 조회해서 모델별을 본다. 그런데 이름표가 영어뿐이다.

그래서 **ccstatusline 을 claude-hud 모양으로 꾸몄다.** 도구는 안 고친다.

## 포크를 안 뜬다

한국어를 넣겠다고 도구 소스를 고치면, 그 도구가 업데이트될 때마다 다시 고쳐야 한다.
여기서는 **설정 파일 하나**로 끝낸다.

```jsonc
// 1. rawValue 로 위젯의 영어 이름표를 뗀다
{ "type": "context-percentage", "rawValue": true }     // "Ctx Used: 62%" → "62%"

// 2. 그 앞에 custom-text 로 원하는 말을 넣는다
{ "type": "custom-text", "customText": "컨텍스트 " }
```

`npm update` 해도 안 깨진다. 언어를 바꾸는 것도 파일 하나 갈아 끼우는 일이다.

### 값이 없을 때 이름표만 남는 문제

PR 이 없으면 `PR` 이라는 글자만 덩그러니 남는다. 이름표를 값에 **붙여** 둔다.

```jsonc
{
  "type": "custom-text", "customText": "PR ",
  "merge": true,
  "metadata": { "hide": "merge-target-hidden" }   // 값이 숨으면 이름표도 숨는다
}
```

## 알아 둘 함정 다섯

여기서 시간을 썼다. 적어 둔다.

**색은 `hex:RRGGBB` 다.** `#RRGGBB` 는 조용히 무시된다 — 굵게만 들어가고 색이 안 나간다.
오류도 안 난다.

```jsonc
{ "color": "hex:39FF14" }   // ✅
{ "color": "#39FF14" }      // ❌ 아무 일도 안 일어난다
```

**`colorLevel` 이 3 이어야 한다.** 2(ansi256)면 hex 가 가까운 256색으로 뭉개진다.

**Fable 위젯만 이름 순서가 다르다.**

```
weekly-opus-usage     ✅
weekly-sonnet-usage   ✅
weekly-fable-usage    ❌ 이런 건 없다
fable-weekly-usage    ✅ 이거다
```

**막대 문자는 못 바꾼다.** `slider` 는 `▓░`(폭 10), `progress` 는 `[█░]`(대괄호 포함).
둘 중 고르는 것뿐이다. 여기서는 대괄호 없는 `slider` 를 쓴다.

**설정은 `$HOME/.config/ccstatusline/` 에 둬야 한다.** ccstatusline 은 `XDG_CONFIG_HOME`
을 안 본다 — `os.homedir()` 아래 `.config` 를 박아 쓴다. XDG 를 따라 다른 데 두면
파일은 잘 놓이는데 화면은 안 바뀐다. 이것도 오류가 안 난다.

## 사슬 스크립트가 하는 일 셋

상태줄을 바로 부르지 않고 `statusline.sh` 를 한 번 거친다. 이유가 있다.

**`NODE_OPTIONS` 를 끊는다.** 이게 제일 중요하다. 바깥에서 `--require` 로 임시 파일을
preload 하게 걸어 두는 도구가 있는데, 그 임시 파일을 OS 가 청소해 간다. 사라진 뒤에는
node 가 시작조차 못 하고, 그러면 **상태줄은 오류 없이 그냥 안 보인다.** 원인을 찾기가
아주 어렵다. 여기서 끊어 두면 바깥 설정과 무관하게 뜬다.

**`COLUMNS` 를 `stty` 로 실측한다.** stdout 이 파이프라 터미널 폭이 안 물려 내려온다.
안 재면 줄바꿈 계산이 틀려 화면이 접힌다.

**느린 일은 뒤로 보낸다.** 렌더링을 늦추지 않는다.

## 내 맘대로 고치기

`~/.config/ccstatusline/settings.json` 을 열면 된다. `lines` 배열 하나가 화면 한 줄이다.

| 하고 싶은 것 | 어떻게 |
|---|---|
| 막대 없애기 | 그 위젯의 `metadata.display` 를 지운다 |
| 소수점 보기 | `numberFormat` 을 지운다 (`62%` → `62.0%`) |
| 색 바꾸기 | `"color": "hex:FF79C6"` |
| 모델별 숨기기 | 둘째 줄의 `weekly-*-usage`·`fable-weekly-usage` 를 지운다 |
| 위젯 더 보기 | `ccstatusline` 을 그냥 실행하면 고르는 화면이 뜬다 |

되돌리려면 설치할 때 남겨 둔 `settings.json.bak-*` 를 덮어쓰면 된다.

## 무엇이 들어 있나

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

## 언어를 더하려면

`statusline/locales/` 의 아무 파일이나 복사해서 `customText` 만 바꾸면 된다.
고칠 자리는 아홉 군데뿐이고, 색·막대·순서는 안 건드려도 된다. PR 환영.

---

<div align="center">

[ccstatusline](https://github.com/sirmalloc/ccstatusline) 위에 세웠다 · MIT

</div>
