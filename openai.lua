local M = {}

local KEYCHAIN_SERVICE = "hs-llm-hotkeys"
local KEYCHAIN_ACCOUNT = "openai"

local function apiKey()
  local out, ok = hs.execute(string.format(
    "/usr/bin/security find-generic-password -s %s -a %s -w 2>/dev/null",
    KEYCHAIN_SERVICE, KEYCHAIN_ACCOUNT))
  if ok and out then
    local key = out:gsub("%s+$", "")
    if key ~= "" then return key end
  end
end

-- callback(err, text)
function M.chat(opts, callback)
  local key = apiKey()
  if not key then
    callback(string.format(
      "APIキーがキーチェーンにありません。\nsecurity add-generic-password -s %s -a %s -w",
      KEYCHAIN_SERVICE, KEYCHAIN_ACCOUNT))
    return
  end

  local body = {
    model = opts.model,
    messages = {
      { role = "system", content = opts.system },
      { role = "user", content = opts.user },
    },
  }
  if opts.reasoningEffort then body.reasoning_effort = opts.reasoningEffort end

  hs.http.asyncPost(
    "https://api.openai.com/v1/chat/completions",
    hs.json.encode(body),
    { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. key },
    function(status, respBody)
      local ok, resp = pcall(hs.json.decode, respBody or "")
      if status ~= 200 then
        local msg = ok and resp and resp.error and resp.error.message or respBody
        callback(string.format("OpenAI API error (%s): %s", status, msg))
        return
      end
      local text = ok and resp.choices and resp.choices[1] and resp.choices[1].message.content
      if not text then
        callback("OpenAI API のレスポンスを解釈できませんでした")
        return
      end
      callback(nil, text)
    end
  )
end

return M
