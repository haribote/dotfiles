return {
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "marilari88/neotest-vitest" },
    opts = { adapters = { ["neotest-vitest"] = {} } },
  },
}
