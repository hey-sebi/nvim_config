---@type overseer.ComponentFileDefinition
return {
  desc = "vim.notify when task is started",
  params = {
    title = {
      desc = "Notification title",
      type = "string",
      default = "Overseer",
    },
  },
  constructor = function(params)
    return {
      on_start = function(self, task)
        vim.notify(string.format("Task started: %s", task.name), vim.log.levels.INFO, {
          title = params.title or "Overseer",
        })
      end,
    }
  end,
}
