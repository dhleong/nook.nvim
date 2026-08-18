local nio = require("nio")
-- NOTE: Most of this is nonsense; just use nio

local M = {}

local function pack(...)
  return { ... }
end

function M.maybe_async(cb)
  return function(f)
    if cb then
      local function f_co()
        local f_status = "running"
        local f_ret = nil
        local this = coroutine.running()
        f(function(...)
          print("callback", ...)
          f_status = "done"
          f_ret = ...
          if coroutine.status(this) == "suspended" then
            print("return")
            coroutine.resume(this, ...)
          end
        end)
        if f_status == "running" then
          coroutine.yield()
        end
        cb(f_ret)
      end
      coroutine.resume(coroutine.create(f_co))
    else
      return f(nil)
    end
  end
end

function M.spawn(f)
  nio.run(f)
end

function M.go(cb)
  return function(f)
    if coroutine.running() == nil then
      M.spawn(function()
        print("run f")
        local r = f()
        print("ran f")
        cb(r)
      end)
    else
      print("already in coroutine")
      cb(f())
    end
  end
end

function M.asyncable(f)
  local info = debug.getinfo(f)
  local non_cb_params = info.nparams - 1
  local f_co = function(...)
    local this = coroutine.running()

    local f_status = "running"
    local f_ret = pack()
    local args = pack(...)

    if #args == non_cb_params then
      assert(this ~= nil, "The result of asyncable must be called within a coroutine.")
    else
      -- "Normal" callback invocation
      print("invoking sync", info.name)
      return f(...)
    end

    print("invoking async", info.name)
    f(function(ret)
      f_status = "done"
      f_ret = pack(ret)
      if coroutine.status(this) == "suspended" then
        -- If we are suspended, then f_co has yielded control after calling f.
        -- Use the caller of this callback to resume computation until the next yield.
        local cb_ret = pack(coroutine.resume(this))
        print("got ret", cb_ret)
        return cb_ret
      end
    end, ...)
    if f_status == "running" then
      -- If we are here, then `f` must not have called the callback yet, so it
      -- will do so asynchronously.
      -- Yield control and wait for the callback to resume it.
      print("yielding")
      local yield_ret = coroutine.yield()
      print("returned from yield", yield_ret)
    end
    return unpack(f_ret, 1, #f_ret)
  end
  return f_co
end

return M
