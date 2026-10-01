# hs-llm-hotkeys

Hammerspoon で動く、OpenAI API (BYOK) を使った選択テキスト翻訳とスニペット検索・貼り付け。

| ショートカット | 動作 |
|---|---|
| `ctrl+i` | 選択テキストを翻訳してポップアップ表示（日本語→英語、それ以外→日本語）。Enter でコピーして閉じる、Esc で閉じる |
| `ctrl+o` | スニペットを検索。Enter で貼り付け、shift+Enter でコピー、右クリックで削除 |
| `ctrl+shift+o` | 選択テキスト（なければクリップボード）にタイトルを付けてスニペット登録 |

メニューバーの「訳」からも同じ操作と `snippets.json` の直接編集ができる。

## セットアップ

```sh
brew install --cask hammerspoon
./install.sh
# OpenAI API キーをキーチェーンに保存（プロンプトで入力）
security add-generic-password -s hs-llm-hotkeys -a openai -w
```

Hammerspoon を起動し、アクセシビリティ権限を許可する。

## 設定

`~/.hammerspoon/init.lua` の `start()` に渡すと上書きできる。

```lua
require("hs-llm-hotkeys").start({
  model = "gpt-6-luna",
  reasoningEffort = "low", -- 推論非対応モデルでは nil にする
  snippetsPath = os.getenv("HOME") .. "/.config/hs-llm-hotkeys/snippets.json",
  hotkeys = { translate = { { "ctrl" }, "i" } },
})
```

スニペットは `snippetsPath` の JSON（`[{ "title": ..., "content": ... }]`）に保存される。
