# hs-llm-hotkeys

Hammerspoon で動く、OpenAI API (BYOK) を使った選択テキスト翻訳とスニペット検索・貼り付け。

| ショートカット | 動作 |
|---|---|
| `ctrl+i` | 選択テキストを翻訳してポップアップ表示（日本語→英語、それ以外→日本語）。Enter でコピーして閉じる、Esc で閉じる |
| `ctrl+o` | スニペットを検索。Enter で貼り付け、shift+Enter でコピー、右クリックで削除 |
| `ctrl+shift+o` | タイトルと内容を入力してスニペット登録（選択中のテキストがあれば内容に入る）。cmd+Enter で保存 |

メニューバーの「訳」からも同じ操作と `snippets.json` の直接編集ができる。

## セットアップ

```sh
brew install --cask hammerspoon
git clone https://github.com/fukubaka0825/hs-llm-hotkeys.git
cd hs-llm-hotkeys
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

## データの取り扱いと料金

- 翻訳を実行すると、選択したテキストを OpenAI API に送信する。
- OpenAI API キーは macOS のキーチェーンに保存し、API 利用料金は各自の OpenAI アカウントに課金される。
- スニペットはローカルの JSON ファイルに保存する。スニペットの検索・登録・貼り付けでは OpenAI API に送信しない。

## 運用方針

個人用ツールとして公開している。外部からの Pull Request と Issues は受け付けていない。

## ライセンス

[MIT License](LICENSE)
