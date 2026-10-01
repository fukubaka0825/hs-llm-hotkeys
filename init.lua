local translate = require("hs-llm-hotkeys.translate")
local snippets = require("hs-llm-hotkeys.snippets")

local M = {}

local defaults = {
  model = "gpt-6-luna",
  -- 翻訳に深い推論は不要で、応答速度を優先するため
  reasoningEffort = "low",
  snippetsPath = os.getenv("HOME") .. "/.config/hs-llm-hotkeys/snippets.json",
  hotkeys = {
    translate = { { "ctrl" }, "i" },
    searchSnippets = { { "ctrl" }, ";" },
    registerSnippet = { { "ctrl", "shift" }, ";" },
  },
}

local function merge(base, override)
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(override or {}) do out[k] = v end
  return out
end

function M.start(userConfig)
  userConfig = userConfig or {}
  local config = merge(defaults, userConfig)
  -- ホットキーは一部だけ上書きしたいことが多いので、個別にマージする
  config.hotkeys = merge(defaults.hotkeys, userConfig.hotkeys)
  snippets.setup(config)

  local hk = config.hotkeys
  hs.hotkey.bind(hk.translate[1], hk.translate[2], function() translate.run(config) end)
  hs.hotkey.bind(hk.searchSnippets[1], hk.searchSnippets[2], snippets.search)
  hs.hotkey.bind(hk.registerSnippet[1], hk.registerSnippet[2], snippets.register)

  M.menu = hs.menubar.new()
  M.menu:setTitle("訳")
  M.menu:setMenu({
    { title = "選択テキストを翻訳", fn = function() translate.run(config) end },
    { title = "スニペットを検索", fn = snippets.search },
    { title = "選択テキスト／クリップボードをスニペット登録", fn = snippets.register },
    { title = "snippets.json を開く", fn = snippets.openFile },
    { title = "-" },
    { title = "設定を再読み込み", fn = hs.reload },
  })
end

return M
