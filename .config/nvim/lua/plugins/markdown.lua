return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "yaml", "mermaid" },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft["markdown"] = {}
      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
        opts.formatters_by_ft[ft] = vim.tbl_filter(function(f)
          return f ~= "markdownlint-cli2"
        end, opts.formatters_by_ft[ft] or {})
      end
      return opts
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return pkg ~= "markdownlint-cli2"
      end, opts.ensure_installed or {})
      return opts
    end,
  },
}
