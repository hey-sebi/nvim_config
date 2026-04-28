return {
  "nvim-neotest/neotest",
  keys = {
    -- unbind defaults: <leader>t conflicts with my terminal keybindings. Instead we use N for neotest (n is noice already).
    { "<leader>N", false },
    { "<leader>Na", false },
    { "<leader>Nt", false },
    { "<leader>NT", false },
    { "<leader>Nr", false },
    { "<leader>Nl", false },
    { "<leader>Ns", false },
    { "<leader>No", false },
    { "<leader>NO", false },
    { "<leader>NS", false },
    { "<leader>Nw", false },
    -- set the new keybindings
    { "<leader>N", "", desc = "+test" },
    {
      "<leader>Na",
      function()
        require("neotest").run.attach()
      end,
      desc = "Attach to Test (Neotest)",
    },
    {
      "<leader>Nt",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run File (Neotest)",
    },
    {
      "<leader>NT",
      function()
        require("neotest").run.run(vim.uv.cwd())
      end,
      desc = "Run All Test Files (Neotest)",
    },
    {
      "<leader>Nr",
      function()
        require("neotest").run.run()
      end,
      desc = "Run Nearest (Neotest)",
    },
    {
      "<leader>Nl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run Last (Neotest)",
    },
    {
      "<leader>Ns",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Toggle Summary (Neotest)",
    },
    {
      "<leader>No",
      function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end,
      desc = "Show Output (Neotest)",
    },
    {
      "<leader>NO",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Toggle Output Panel (Neotest)",
    },
    {
      "<leader>NS",
      function()
        require("neotest").run.stop()
      end,
      desc = "Stop (Neotest)",
    },
    {
      "<leader>Nw",
      function()
        require("neotest").watch.toggle(vim.fn.expand("%"))
      end,
      desc = "Toggle Watch (Neotest)",
    },
  },
}
