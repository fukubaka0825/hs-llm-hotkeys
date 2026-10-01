local selection = require("hs-llm-hotkeys.selection")

local M = {}

local path

local function load()
  return hs.json.read(path) or {}
end

local function save(items)
  hs.fs.mkdir(path:match("(.+)/[^/]+$"))
  hs.json.write(items, path, true, true)
end

local function preview(content)
  local line = content:gsub("%s+", " ")
  if utf8.len(line) > 80 then
    line = line:sub(1, utf8.offset(line, 81) - 1) .. "…"
  end
  return line
end

local chooser

local function choices()
  local list = {}
  for i, item in ipairs(load()) do
    list[#list + 1] = { text = item.title, subText = preview(item.content), index = i }
  end
  return list
end

local function remove(index)
  local items = load()
  local item = items[index]
  if not item then return end
  local button = hs.dialog.blockAlert("「" .. item.title .. "」を削除しますか？", "", "削除", "キャンセル")
  if button ~= "削除" then return end
  table.remove(items, index)
  save(items)
end

function M.setup(config)
  path = config.snippetsPath
  chooser = hs.chooser.new(function(choice)
    if not choice then return end
    local item = load()[choice.index]
    if not item then return end
    -- shift+Enter はコピーだけにして、貼り付け先を後から選べるようにする
    if hs.eventtap.checkKeyboardModifiers().shift then
      hs.pasteboard.setContents(item.content)
      hs.alert.show("コピーしました: " .. item.title)
    else
      -- chooser が閉じて元のアプリにフォーカスが戻るのを待ってから貼り付ける
      hs.timer.doAfter(0.1, function() selection.paste(item.content) end)
    end
  end)
  chooser:searchSubText(true)
  chooser:placeholderText("スニペットを検索（Enter: 貼り付け / shift+Enter: コピー / 右クリック: 削除）")
  chooser:rightClickCallback(function(row)
    local choice = chooser:selectedRowContents(row)
    if not choice or not choice.index then return end
    chooser:hide()
    remove(choice.index)
  end)
end

function M.search()
  chooser:choices(choices())
  chooser:query(nil)
  chooser:show()
end

local FORM_HTML = [[
<!doctype html><html><head><meta charset="utf-8"><style>
  :root { color-scheme: light dark; }
  body { margin: 0; padding: 14px 16px; box-sizing: border-box; height: 100vh;
         display: flex; flex-direction: column; gap: 8px;
         font: 13px/1.5 -apple-system, "Hiragino Sans", sans-serif; background: Canvas; color: CanvasText; }
  label { font-size: 11px; color: GrayText; }
  input, textarea { font: inherit; padding: 6px 8px; border-radius: 6px; color: inherit; background: Field;
                    border: 1px solid color-mix(in srgb, GrayText 40%, transparent); }
  textarea { flex: 1; resize: none; }
  footer { display: flex; justify-content: space-between; align-items: center; font-size: 11px; color: GrayText; }
  #error { color: #d33; }
  button { font: inherit; padding: 4px 14px; }
</style></head><body>
  <label for="title">タイトル</label>
  <input id="title" autocomplete="off">
  <label for="content">内容</label>
  <textarea id="content"></textarea>
  <footer><span id="error">cmd+Enter: 保存　Esc: キャンセル</span><button id="save">保存</button></footer>
<script>
  const init = __INIT__;
  const title = document.getElementById("title");
  const content = document.getElementById("content");
  content.value = init.content;
  title.focus();
  function save() {
    if (!title.value.trim() || !content.value.trim()) {
      document.getElementById("error").textContent = "タイトルと内容の両方を入力してください";
      return;
    }
    window.webkit.messageHandlers.hs.postMessage({ title: title.value.trim(), content: content.value });
  }
  document.getElementById("save").addEventListener("click", save);
  document.addEventListener("keydown", (e) => {
    if (e.key === "Enter" && e.metaKey && !e.isComposing) { e.preventDefault(); save(); }
  });
</script></body></html>
]]

local form

-- 選択中のテキストがあれば内容の初期値にする。クリップボードは使わない。
-- 意図しない古いコピー内容が入り込み、登録したい内容と食い違うため
function M.register()
  local initial = selection.get() or ""
  if form then form:delete() end

  local uc = hs.webview.usercontent.new("hs")
  uc:setCallback(function(msg)
    local items = load()
    items[#items + 1] = { title = msg.body.title, content = msg.body.content }
    save(items)
    hs.alert.show("登録しました: " .. msg.body.title)
    -- 自身のメッセージコールバック中に webview を破棄するとクラッシュしうるので、次のループで閉じる
    local done = form
    form = nil
    hs.timer.doAfter(0, function() if done then done:delete() end end)
  end)

  local screen = hs.mouse.getCurrentScreen():frame()
  local w, h = 520, 380
  -- JSON を script 内に直接埋め込むため、内容に含まれる "</script>" で HTML が壊れないようにする
  local init = hs.json.encode({ content = initial }):gsub("</", "<\\/")
  form = hs.webview.new({ x = screen.x + (screen.w - w) / 2, y = screen.y + (screen.h - h) / 3, w = w, h = h },
      {}, uc)
    :windowStyle({ "titled", "closable", "resizable" })
    :windowTitle("スニペットを登録")
    :level(hs.drawing.windowLevels.floating)
    :allowTextEntry(true)
    :closeOnEscape(true)
    :deleteOnClose(true)
    :windowCallback(function(action, wv)
      if action == "closing" and wv == form then form = nil end
    end)
    :html((FORM_HTML:gsub("__INIT__", function() return init end)))
    :show()
  form:hswindow():focus()
end

function M.openFile()
  if not hs.fs.attributes(path) then save({}) end
  hs.execute(string.format("/usr/bin/open -t %q", path))
end

return M
