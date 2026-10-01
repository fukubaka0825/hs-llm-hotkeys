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

-- 選択中のテキストがなければクリップボードを登録対象にする。
-- コピー済みの文章をそのまま残したい場面が多いため
function M.register()
  local content = selection.get() or hs.pasteboard.getContents()
  if not content or content == "" then
    hs.alert.show("登録するテキストを選択するかコピーしてください")
    return
  end
  local summary = preview(content)
  local cut = utf8.offset(summary, 31)
  hs.focus()
  local button, title = hs.dialog.textPrompt(
    "スニペットを登録", summary, cut and summary:sub(1, cut - 1) or summary, "登録", "キャンセル")
  if button ~= "登録" then return end
  title = title:gsub("^%s+", ""):gsub("%s+$", "")
  if title == "" then
    hs.alert.show("タイトルが空のため登録しませんでした")
    return
  end
  local items = load()
  items[#items + 1] = { title = title, content = content }
  save(items)
  hs.alert.show("登録しました: " .. title)
end

function M.openFile()
  if not hs.fs.attributes(path) then save({}) end
  hs.execute(string.format("/usr/bin/open -t %q", path))
end

return M
