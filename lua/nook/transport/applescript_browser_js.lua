local nio = require("nio")
local strings = require("nook.util.strings")

local chrome_style = {
  list = [[
on run argv
    set needle to item 1 of argv
    set out to {}
    set tabChar to character id 9
    if application $appName is running then
      tell application $appName
          repeat with w in windows
              repeat with t in tabs of w
                  if URL of t contains needle then
                      set end of out to (id of t) & tabChar & (URL of t)
                  end if
              end repeat
          end repeat
      end tell
    end if
    set AppleScript's text item delimiters to linefeed
    return out as text
end run
]],
  exec = [[
on run argv
    set tabId to item 1 of argv
    set js to item 2 of argv
    tell application $appName
        repeat with w in windows
            repeat with t in tabs of w
                if (id of t) is tabId then
                    return execute t javascript js
                end if
            end repeat
        end repeat
    end tell
    error "tab not found: " & tabId
end run
]],
}

---@class ApplescriptBrowserJsTransportOpts
local defaults = {
  applications = {
    ["Arc"] = chrome_style,
    ["Google Chrome"] = chrome_style,
  },
}

---@class ApplescriptBrowserJsTransportOpts
local ApplescriptBrowserJsTransport = {}

---@param opts? ApplescriptBrowserJsTransportOpts
function ApplescriptBrowserJsTransport:new(opts)
  local o = vim.tbl_deep_extend("force", {}, opts or defaults)

  setmetatable(o, self)
  self.__index = self

  return o
end

function ApplescriptBrowserJsTransport:_browser_script(browser, script_kind)
  return string.gsub(self.applications[browser][script_kind], "$appName", '"' .. browser .. '"')
end

---@param browser string
function ApplescriptBrowserJsTransport:_list_tabs(browser, params)
  local proc = nio.process.run({
    cmd = "osascript",
    args = { "-e", self:_browser_script(browser, "list"), params.url or "" },
  })
  assert(proc, "Failed to launch osascript")
  local out = strings.trim(proc.stdout.read())
  proc.close()

  if not out or out == "" then
    return {}
  end

  local tabs = strings.split(out, "\r")
  return vim.tbl_map(function(row)
    local parts = strings.split_one(row, "\t")
    return {
      id = parts[1],
      url = parts[2],
    }
  end, tabs)
end

function ApplescriptBrowserJsTransport:connect(params)
  if not vim.fn.executable("osascript") then
    return false
  end

  for k, _ in pairs(self.applications) do
    local tabs = self:_list_tabs(k, params)
    if #tabs > 0 then
      -- TODO: Maybe... choose?
      self._last_tab = tabs[1]
      self._last_params = params
      self._last_browser = k
      return true
    end
  end

  return false
end

function ApplescriptBrowserJsTransport:destroy()
  -- nop
end

function ApplescriptBrowserJsTransport:evaluate(code)
  local tab = self._last_tab

  -- TODO: We may have a new tab that we should switch to
  if not tab then
    local tabs = self:_list_tabs(self._last_browser, self._last_params)
    if not tabs or #tabs == 0 then
      error("Tab gone")
    end
    tab = tabs[1]
  end

  local wrapped = [[
  try {
    JSON.stringify({
      status: 'success',
      result: JSON.stringify(]] .. code .. [[, null, 2)
    })
  } catch (e) {
    JSON.stringify({
      status: 'error',
      stack: e.stack,
      message: e.message
    })
  }
  ]]

  local proc = nio.process.run({
    cmd = "osascript",
    args = {
      "-e",
      self:_browser_script(self._last_browser, "exec"),
      tab.id,
      wrapped,
    },
  })
  assert(proc, "Failed to launch osascript")
  local serialized = proc.stdout.read()
  proc.close()

  if not serialized then
    error("No output from exec script")
  end

  -- This feels kinda bad, but if we don't wrap the result
  -- object in stringify then we just get `null`...
  local js_string = vim.json.decode(serialized)
  local output = vim.json.decode(js_string)
  if output.status == "success" then
    return output.result
  else
    local err = output.message
    if output.stack then
      err = err .. "\n" .. output.stack
    end
    error(err or "unspecified error")
  end
end

return ApplescriptBrowserJsTransport
