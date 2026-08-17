<div align="center">

<img src="assets/banner.svg" width="100%" alt="Script Breakdown Workflow · a DeepSeek Harness agent preset">

**Turn a screenplay into AI-video pre-production assets — shot list, character/scene/prop sheets, per-shot prompts**

A DeepSeek Harness run mode · copy one folder and it's live · the entire methodology is plain markdown

[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-Agent%20Preset-00E0C7?style=flat-square)](https://github.com/deepseek-ai/deepseek-harness)
[![Structure](https://img.shields.io/badge/4%20skills-3%20stages-0A0A0A?style=flat-square)](#how-it-works)
[![Customize](https://img.shields.io/badge/customize-edit%20markdown-0A0A0A?style=flat-square)](#its-only-a-skeleton)
[![License](https://img.shields.io/badge/license-Apache--2.0-6B6B6B?style=flat-square)](LICENSE)

English · [简体中文](README.md)

</div>

---

## What this is

In August 2026 DeepSeek open-sourced its own agent harness, `dsh`. It lets you package a whole way of working as a **run mode** (an agent preset): one directory, copied into place, and a new AI of your own shows up in the Web UI's mode dropdown.

This repo is one of those modes. **It's called Script Breakdown Workflow, and it does exactly one thing: turn a screenplay into pre-production assets for AI video generation.**

Switch to this mode, hand it a script, and it will:

1. **Classify it** — short-form/web drama, feature/series, or commercial. Shot granularity differs completely between them.
2. **Break it down the way a director briefs a crew** — logline, theme and emotional register, narrative structure, scene overview, director's statement — then list **every shot** (number / scene / shot size / camera move / action / dialogue / duration / notes).
3. **Build a visual asset library** — one Chinese Jimeng prompt per character, location and prop, each with cross-shot consistency anchors.
4. **Write per-shot video prompts** — one seven-part Jimeng prompt per shot, ready to paste straight into the generator.

The output is a structured markdown package in your workspace that you can **start working from immediately**.

> **It does not generate video or images, and calls no generation API.** It does the other half of the job — the half that is laborious, easy to get inconsistent, and that nobody wants to do.

---

## Install in 60 seconds

**Prerequisites**: Node.js, and having run the Harness at least once (so that `~/.dsh` exists).

```bash
npx @deepseek-ai/dsh web
```

**Install**:

```bash
git clone https://github.com/feicaiclub/script-breakdown-dsh.git
cd script-breakdown-dsh && ./install.sh
```

The script does one thing: copy `preset/` to `~/.dsh/.agent-presets/script-breakdown/`. Preset directories are re-scanned on every read, so it is **live immediately — no restart**.

**Use it**: open the Web UI → switch the mode dropdown to 剧本拆解工作流 → drop in a `.txt` / `.md` script (or just paste the text) → say "break down this script".

Uninstall: `./install.sh --uninstall`

---

## How it works

<img src="assets/01-pipeline.svg" width="100%" alt="Three-stage pipeline: input, classification, stage 1, confirmation gate, stage 2, confirmation gate, stage 3, output package">

Three stages, with **a confirmation gate between each one**. It will not run the whole thing and dump a pile of files on you — after each stage lands on disk it stops, reports the paths and the key numbers, and asks: continue / revise / redo.

| Stage | Skill | Reads | Writes |
|---|---|---|---|
| **1 · Director's breakdown & shot list** | `script-breakdown-stage1` | full script + classification | `00-拆解报告.md` (theme / structure / scenes / director's statement)<br>`01-分镜总表.md` (eight-column shot list) |
| **2 · Asset prompts** | `script-asset-prompts` | `01` + the script | `02-资产提示词.md` (characters / locations / props + consistency anchors + asset index) |
| **3 · Per-shot video prompts** | `script-shot-prompts` | `01` + `02` | `03-逐镜视频提示词.md` (one seven-part prompt per shot) |

A fourth skill, `script-breakdown`, is the router that orchestrates all of it: classification, stage dispatch, output acceptance, redo/backup, and the run log. It never writes the deliverables itself.

### How cross-stage consistency is actually held

Anyone who has done AI video knows the painful part: **the same character does not look the same in shot 3 and shot 11.**

This workflow solves it with two hard rules — **upstream files are the single source of truth, and the model is not allowed to recite from memory**:

<img src="assets/03-fact-chain.svg" width="100%" alt="Source-of-truth chain: shot size and camera move come from 01, duration is copied verbatim from 01, character anchors come from 02">

- Stage 2 reads only `01` and the script. Stage 3 reads only `01` and `02` — **it does not even look at the script anymore**
- The duration column is **copied verbatim**; stage 3 may not change it
- Asset anchors ("greying short hair", "faded apron") are quoted into every shot **word for word**
- Nothing may be introduced that isn't in `01` / `02`; the prompt count matches the shot count one to one

### Redo, backup, run log

Revising is the normal case. Say "redo the shot list" or "change shot 7" and it will:

1. Copy the current file into `历史版本/` as `01-分镜总表.v2.20260817-031318.md`
2. Regenerate
3. Append a row to `.script-breakdown/run-log.md` (metadata and paths only — **never script or prompt text**)
4. Warn you that downstream files may now be stale and ask whether to redo those too — your call; it never cascades on its own

**Zero shell, zero deletion** throughout. Every backup is kept; when they pile up it tells you to clean them out yourself in your file manager.

---

## What the output looks like

```
拆解结果/<script name>/
├─ 原始剧本.md            # only when you pasted text; uploaded files are never touched
├─ 00-拆解报告.md          # breakdown report
├─ 01-分镜总表.md          # shot list
├─ 02-资产提示词.md        # asset prompts
├─ 03-逐镜视频提示词.md    # per-shot video prompts
└─ 历史版本/               # automatic backups before every redo, all kept

.script-breakdown/
└─ run-log.md              # timestamp, action, output path for every step
```

Below are the reference examples that ship in the repo's own templates — this is what the output looks like:

**`01-分镜总表.md`**

| 镜号 | 场次 | 景别 | 运镜 | 画面内容 | 台词/旁白 | 时长 | 备注 |
|---|---|---|---|---|---|---|---|
| 01 | 第1场 | 中景 | 固定 | 面馆内，小雨推门而入，风铃晃动，老板抬头。 | 小雨：老板，一碗阳春面。 | 5秒 | 门铃音效 |
| 02 | 第1场 | 特写 | 推 | 老板的手把荷包蛋轻轻打进面碗。 | — | 5秒 | 热气升腾 |

**`02-资产提示词.md`**

> ### 小雨（25 岁，互联网公司职员）
>
> ```text
> 25 岁左右的中国年轻女性，圆脸，齐肩黑发微乱，眼下有熬夜的青色；穿浅灰连帽卫衣，
> 袖口起球，双肩包单肩挎着；体态疲惫，走路略拖，坐定时习惯把手机屏幕按灭又点亮。
> ```
>
> - 一致性锚点：齐肩黑发、浅灰连帽卫衣、眼下青色

**`03-逐镜视频提示词.md`**

> ### 镜 04 · 第1场 · 近景固定
>
> ```text
> 小雨（齐肩黑发、浅灰连帽卫衣、眼下青色）坐在吧台前低头吃面，
> 第一口咽下后眼眶发红，一滴泪滑进碗里，动作停顿。深夜面馆内景，
> 暖黄灯光。镜头：近景，固定机位。光线柔和的侧光，氛围克制而动人。
> 时长 10 秒。
> ```

No lead-in text before the code block — so you can copy the whole thing in one go.

---

## It's only a skeleton

Please read this section. It decides whether you'll be disappointed.

**Where this came from:** I first had DeepSeek search the web for how script breakdown is generally done and how AI-video prompts are generally written — the **common requirements and the common process** — and then built that into a working framework on DeepSeek Harness.

So it is a **generic skeleton, not a finished product**:

- Shot granularity uses generic defaults (5s baseline, 3s for fast cuts, 10s for emotional beats), not your production's
- Prompt constraints are **deliberately loose** — they guarantee subject, action, environment, camera language, lighting and duration are present, but nothing is pinned to hard quantitative standards
- The seven-part structure targets **Jimeng**; another platform needs another structure
- Asset prompts cover appearance / wardrobe / material / consistency only — no overall art direction, no micro-expressions, no frame-accurate timeline

**It runs, but it doesn't know your industry.** A brand TVC team, a vertical short-drama team and a product-animation team do not need the same shot list at all.

The good news: **filling in your own standards takes almost no code.**

---

## Making it yours

<img src="assets/04-customize-map.svg" width="100%" alt="Customization map: template layer, constraint layer, methodology layer, process layer, plus four common modifications">

The entire methodology is markdown. Edit it in any text editor, save, and the next conversation uses the new version — preset directories are re-scanned on every read, so **no restart and no reinstall**.

| Layer | File to edit | What changes |
|---|---|---|
| **Templates** (lightest) | `preset/skills/*/templates/*.md` | Which columns the shot list has, what an asset entry looks like, the order of the seven parts. Swap in your own template and the output format follows immediately |
| **Constraints** | The "硬性规则 / 写作规则" sections of `preset/skills/*/SKILL.md` | Prompt length, duration tiers, banned words, required fields. **This is the layer left loose for you to tighten** |
| **Methodology** | `preset/skills/*/references/*.md` | The directing method, shot density per genre, the long-script chunking threshold. Write your team's standard in here and its thinking becomes yours |
| **Process** (structural) | `preset/agent.cordis.yml` + a new `preset/skills/<your stage>/` | Add or remove stages. Create a skill directory, add one line to the persona, and the pipeline grows a segment |

### The four most common modifications

**① Frame-accurate timing, micro-expressions**
Add columns to `preset/skills/script-breakdown-stage1/templates/storyboard-table.md` (e.g. "micro-expression", "beat"), then change the duration rule in the `SKILL.md` next to it. Stage 3 copies the new duration column automatically.

**② A different video generation platform**
The seven-part structure is Jimeng-specific. For Kling / Hailuo / Veo, replace `preset/skills/script-shot-prompts/templates/jimeng-shot-template.md` wholesale and rewrite the "七段式" and "写作规则" sections of the adjacent `SKILL.md` for the new platform (English input, parameters, negative prompts, and so on).

**③ Overall art direction**
Add a stage before stage 1. Create `preset/skills/script-visual-design/SKILL.md` producing `00-视觉设定.md` (palette, camera-language thesis, reference styles), then add a line to the persona in `preset/agent.cordis.yml` and have later stages reference it.

**④ Voice-over script / subtitles / BGM cues**
Easiest path: copy an existing skill directory as a template — the structure, frontmatter and reference wiring are all there — rename it, rewrite the content, and mount it in the persona.

> Before deciding what to change, run one of your own real scripts end to end. You'll find out fast which layer falls short.

---

## Under the hood

<img src="assets/02-architecture.svg" width="100%" alt="Layers: Web UI mode dropdown, the preset with persona, four skills, five tool rows and compaction, and the DeepSeek Harness host beneath">

```
.
├── install.sh                        install / uninstall
├── preset/
│   ├── preset.yml                    mode name and description (what the dropdown shows)
│   ├── agent.cordis.yml              persona router + tool rows + compaction + skill mounting
│   └── skills/
│       ├── script-breakdown/         router: orchestration, acceptance, redo/backup, run log
│       │   └── references/           chunking & guardrails · redo & run-log · report template · trigger corpus
│       ├── script-breakdown-stage1/  stage 1
│       │   ├── references/           the directing method
│       │   └── templates/            shot list template
│       ├── script-asset-prompts/     stage 2
│       │   └── templates/            asset sheet template
│       └── script-shot-prompts/      stage 3
│           └── templates/            per-shot Jimeng prompt template
└── assets/                           README figures
```

**14 files, 646 lines, roughly 30,000 characters of methodology. Zero TypeScript, zero dependencies, zero build.**

A few design points worth calling out:

- **Skills are progressively disclosed.** Only four `description` lines (~1,250 characters total) stay resident in context. A `SKILL.md` body is read only when it matches; `references/` and `templates/` are read only when that body names them. So 30,000 characters of methodology costs almost nothing day to day.
- **Only five tool rows are mounted**: `tool-fs` / `tool-fs-search` / `tool-ask-user` / `tool-todo` / `tool-skill`. No shell, no network, no generation API — it is physically unable to delete your files or quietly call a service.
- **Skills are preset-scoped**, registered into this mode's own layer, so they don't pollute your other modes.
- **Long scripts are chunked by scene/act** (triggered at 20,000 characters), shot numbers stay continuous across the whole film, and the pieces are merged before anything is written. The threshold is a safety multiple of the host `tool-result-pruner`'s 8,192-character truncation line, not an arbitrary number.
- **Why a preset instead of a plugin**: plugins need TypeScript, bundling and dependencies. A preset is a directory — copy it and it runs, edit it and it's live. For a methodology-shaped product, a preset is the lower-friction vehicle.

---

## Scope and known limits

**What it does not do**

- Generate video or images, or call any generation API
- Read PDF / docx — save as `.txt` / `.md`, or paste the text
- Delete anything, or write outside `拆解结果/` and `.script-breakdown/`
- Process non-scripts (technical docs, prose, data tables) — those are refused outright, with no directory created

**Known limits**

- Prompts are **Chinese** and **Jimeng-flavoured**. Another platform or language means editing templates (see above)
- Files over 500 KB (~200,000 characters) are refused; submit in parts
- If a single chunk of a long script still exceeds context, it stops and asks you to split manually
- Breakdown quality tracks script quality. Blocking the script never specified will not be invented for you — that is deliberate: **shots are derived from what the script actually says, never from invented plot or characters**

---

## Contributing

- Ran your own script and found a layer too loose? Open an issue naming the file and the section
- Built a better template (another platform's dialect, another industry's shot list)? PRs welcome, or just paste it in an issue
- Added a new stage (voice-over, subtitles, cost estimation…)? Especially welcome — that's exactly how this skeleton is supposed to grow

The value here isn't the version I built. It's that **it's a skeleton you can change.**

## License

[Apache-2.0](LICENSE) © FEICAI CLUB

Not affiliated with DeepSeek. DeepSeek Harness is open-sourced by DeepSeek AI under MIT. "Jimeng" is a ByteDance product; this project only produces text prompts aimed at it and calls none of its APIs.

---

<div align="center">

## If this workflow was useful

<a href="https://www.feicaiclub.cn"><img src="assets/feicai-club.png" width="100%" alt="FEICAI CLUB · an AI builder community"></a>

### 废才俱乐部 · FEICAI CLUB

**No hot air / only what actually works**

</div>

This workflow isn't a one-off. It's how we make everything: **read the source, measure the numbers, check them again, and be honest about the costs.**

What the site is publishing now runs along the same line as this repo —

<div align="center">

`#AGENT`　`#SKILL`　`#CLAUDE-CODE`　`#CODEX`　`#HARNESS`<br>`#CONTEXT-ENGINEERING`　`#PROMPT-FRAMEWORK`　`#MCP-TOOLING`　`#RAG`　`#EVAL`

</div>

Beyond AI agents and AI coding, we also cover AI writing, AI comics and short drama, AI image generation and UI design — and how all of it actually lands in a real industry. Alongside the articles there are resource packs, an events area and a paid community.

<div align="center">

### [→ www.feicaiclub.cn](https://www.feicaiclub.cn)

**Subscribe and this kind of deep-dive keeps coming**

<sub>If this workflow has value for you, star the repo ⭐️ — and help more people find it</sub>

</div>
