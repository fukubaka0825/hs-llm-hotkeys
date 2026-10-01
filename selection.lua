local M = {}

local function axSelectedText()
  local ok, text = pcall(function()
    local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    return focused and focused:attributeValue("AXSelectedText")
  end)
  if ok and type(text) == "string" and text ~= "" then
    return text
  end
end

-- AX は Chrome / Electron 系で取れないことが多いため、cmd+c にフォールバックする。
-- その際ユーザーのクリップボードを汚さないよう退避・復元する。
local function copySelectedText()
  local saved = hs.pasteboard.readAllData()
  local before = hs.pasteboard.changeCount()
  hs.eventtap.keyStroke({ "cmd" }, "c", 0)
  for _ = 1, 30 do
    if hs.pasteboard.changeCount() ~= before then break end
    hs.timer.usleep(10000)
  end
  local text
  if hs.pasteboard.changeCount() ~= before then
    text = hs.pasteboard.getContents()
  end
  if saved and next(saved) then
    hs.pasteboard.writeAllData(saved)
  end
  if text and text ~= "" then return text end
end

function M.get()
  return axSelectedText() or copySelectedText()
end

function M.paste(text)
  local saved = hs.pasteboard.readAllData()
  hs.pasteboard.setContents(text)
  hs.eventtap.keyStroke({ "cmd" }, "v", 0)
  -- 貼り付け先アプリが pasteboard を読み終える前に戻すと古い内容が貼られるため少し待つ
  hs.timer.doAfter(0.5, function()
    if saved and next(saved) then hs.pasteboard.writeAllData(saved) end
  end)
end

return M
