-- mirrors ghostty's built-in "Material Design Colors" theme
-- (see /Applications/Ghostty.app/Contents/Resources/ghostty/themes/Material Design Colors)
-- so nvim's colorscheme matches the terminal instead of clashing with it.
require("mini.base16").setup({
  palette = {
    base00 = "#1d262a", -- background
    base01 = "#2a363b", -- lighter background
    base02 = "#4e6a78", -- selection background
    base03 = "#a1b0b8", -- comments, bright black
    base04 = "#435b67", -- dark foreground, black
    base05 = "#e7ebed", -- default foreground
    base06 = "#ffffff", -- light foreground
    base07 = "#ffffff", -- light background
    base08 = "#fc3841", -- red
    base09 = "#fc746d", -- orange (bright red)
    base0A = "#fed032", -- yellow
    base0B = "#5cf19e", -- green
    base0C = "#59ffd1", -- cyan
    base0D = "#37b6ff", -- blue
    base0E = "#fc669b", -- magenta (bright magenta)
    base0F = "#fc226e", -- brown slot, magenta
  },
  use_cterm = true,
  plugins = { default = true },
})
vim.g.colors_name = "ghostty-material"
