local selection = require("hs-llm-hotkeys.selection")
local openai = require("hs-llm-hotkeys.openai")

local M = {}

-- 日本語判定をモデルに任せるのは、漢字のみの文（例: 「東京駅」）を
-- かな有無の機械判定では日本語と中国語で区別できないため
local SYSTEM_PROMPT = [[You are a professional translator.
If the text inside <text> is Japanese, translate it into natural English.
Otherwise, translate it into natural Japanese.
Output only the translation. Do not add explanations or quotes.
Preserve line breaks, Markdown, code, URLs and proper nouns.]]

local WIDTH, HEIGHT = 560, 320

local HTML = [[
<!doctype html><html><head><meta charset="utf-8"><style>
  :root { color-scheme: light dark; }
  body { margin: 0; font: 14px/1.6 -apple-system, "Hiragino Sans", sans-serif;
         background: Canvas; color: CanvasText; display: flex; flex-direction: column; height: 100vh; }
  #result { flex: 1; overflow: auto; padding: 14px 16px; white-space: pre-wrap; user-select: text; }
  #result.loading, #result.error { color: GrayText; }
  #result.error { color: #d33; }
  footer { padding: 6px 16px; font-size: 11px; color: GrayText; border-top: 1px solid color-mix(in srgb, GrayText 30%, transparent); }
</style></head><body>
  <div id="result" class="loading">翻訳中…</div>
  <footer>Enter: コピーして閉じる　Esc: 閉じる</footer>
<script>
  function setResult(p) {
    const el = document.getElementById("result");
    el.textContent = p.text;
    el.className = p.error ? "error" : "";
  }
  document.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && !e.isComposing) {
      window.webkit.messageHandlers.hs.postMessage("copy");
    }
  });
</script></body></html>
]]

local popup, result, loaded, pending

local function closePopup()
  if popup then popup:delete() end
  popup, result, loaded, pending = nil, nil, false, nil
end

local function popupFrame()
  local mouse = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen():frame()
  local x = math.min(math.max(mouse.x - WIDTH / 2, screen.x), screen.x + screen.w - WIDTH)
  local y = math.min(mouse.y + 16, screen.y + screen.h - HEIGHT)
  return { x = x, y = y, w = WIDTH, h = HEIGHT }
end

local function openPopup()
  closePopup()
  local uc = hs.webview.usercontent.new("hs")
  uc:setCallback(function(msg)
    if msg.body == "copy" and result then
      hs.pasteboard.setContents(result)
      closePopup()
    end
  end)
  popup = hs.webview.new(popupFrame(), { developerExtrasEnabled = false }, uc)
    :windowStyle({ "titled", "closable", "resizable", "utility" })
    :windowTitle("翻訳")
    :level(hs.drawing.windowLevels.floating)
    :allowTextEntry(true)
    :closeOnEscape(true)
    :deleteOnClose(true)
    :windowCallback(function(action, wv)
      -- 古いポップアップの closing 通知で新しいポップアップの状態を消さないよう同一性を確認する
      if action == "closing" and wv == popup then popup, result, loaded, pending = nil, nil, false, nil end
    end)
    :navigationCallback(function(action, wv)
      if action == "didFinishNavigation" and wv == popup then
        loaded = true
        if pending then wv:evaluateJavaScript(pending) end
        pending = nil
      end
    end)
    :html(HTML)
    :show()
  popup:hswindow():focus()
end

local function render(text, isError)
  if not popup then return end
  local js = "setResult(" .. hs.json.encode({ text = text, error = isError or false }) .. ")"
  -- キー未設定などで即座にエラーが返ると HTML の読み込み前に呼ばれるため、読み込み完了まで保留する
  if loaded then popup:evaluateJavaScript(js) else pending = js end
end

function M.run(config)
  local text = selection.get()
  if not text then
    hs.alert.show("翻訳するテキストを選択してください")
    return
  end
  openPopup()
  local target = popup
  openai.chat({
    model = config.model,
    reasoningEffort = config.reasoningEffort,
    system = SYSTEM_PROMPT,
    user = "<text>\n" .. text .. "\n</text>",
  }, function(err, translated)
    -- 応答待ちの間に次の翻訳を始めていた場合、古い結果で上書きしない
    if popup ~= target then return end
    if err then
      render(err, true)
      return
    end
    result = translated
    render(translated)
  end)
end

return M
