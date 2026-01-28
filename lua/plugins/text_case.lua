return {
  {
    "johmsalas/text-case.nvim",
    config = function()
      require("textcase").setup({})
    end,
    keys = {
      -- Normal mode applies to the word where the cursor is on
      {
        "<leader>cts",
        function()
          require("textcase").current_word("to_snake_case")
        end,
        desc = "Transform: snake_case",
        mode = "n",
      },
      {
        "<leader>ctc",
        function()
          require("textcase").current_word("to_camel_case")
        end,
        desc = "Transform: camelCase",
        mode = "n",
      },
      {
        "<leader>ctp",
        function()
          require("textcase").current_word("to_pascal_case")
        end,
        desc = "Transform: PascalCase",
        mode = "n",
      },
      {
        "<leader>ctk",
        function()
          require("textcase").current_word("to_dash_case")
        end,
        desc = "Transform: dash-case",
        mode = "n",
      },
      {
        "<leader>ctu",
        function()
          require("textcase").current_word("to_constant_case")
        end,
        desc = "Transform: CONSTANT_CASE",
        mode = "n",
      },
      {
        "<leader>ct.",
        function()
          require("textcase").current_word("to_dot_case")
        end,
        desc = "Transform: dot.case",
        mode = "n",
      },
      {
        "<leader>ctT",
        function()
          require("textcase").current_word("to_title_case")
        end,
        desc = "Transform: Title Case",
        mode = "n",
      },

      -- Visual mode: selection
      {
        "<leader>cts",
        function()
          require("textcase").operator("to_snake_case")
        end,
        desc = "Transform: snake_case",
        mode = "x",
      },
      {
        "<leader>ctc",
        function()
          require("textcase").operator("to_camel_case")
        end,
        desc = "Transform: camelCase",
        mode = "x",
      },
      {
        "<leader>ctp",
        function()
          require("textcase").operator("to_pascal_case")
        end,
        desc = "Transform: PascalCase",
        mode = "x",
      },
      {
        "<leader>ctk",
        function()
          require("textcase").operator("to_dash_case")
        end,
        desc = "Transform: dash-case",
        mode = "x",
      },
      {
        "<leader>ctu",
        function()
          require("textcase").operator("to_constant_case")
        end,
        desc = "Transform: CONSTANT_CASE",
        mode = "x",
      },
      {
        "<leader>ct.",
        function()
          require("textcase").operator("to_dot_case")
        end,
        desc = "Transform: dot.case",
        mode = "x",
      },
      {
        "<leader>ctT",
        function()
          require("textcase").operator("to_title_case")
        end,
        desc = "Transform: Title Case",
        mode = "x",
      },
    },
  },
}
