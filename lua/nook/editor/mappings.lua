local Callables = require("nook.editor.callables")

local keys = {
  {
    "cp",
    Callables.prepare_eval_motion,
    desc = '[nook] Evaluate ("print") a motion',
  },
  {
    "cqp",
    Callables.prompt_eval,
    desc = '[nook] Open the replish ("quick prompt")',
  },
  {
    "cqc",
    "cqp<c-f>i",
    desc = "[nook] Open the replish cmd window",
    remap = true,
    layer = "extra",
  },
}

local commands = {
  {
    "NookConnect",
    Callables.connect,
    desc = "[nook] Connect to REPL",
  },

  {
    "Last",
    Callables.last,
    bang = true,
    desc = "[nook] Open preview window with last printed output",
  },
}

return {
  keys = keys,
  commands = commands,
}
