return {
	{
		"bjarneo/hackerman.nvim",
		dependencies = { "bjarneo/aether.nvim" },
		priority = 1000,
		config = function()
			require("hackerman").setup({
				override = {
					Normal = { bg = "#000000", fg = "#00FF00" },
					NormalFloat = { bg = "#0D1A0D", fg = "#00FF00" },
					FloatBorder = { bg = "#0D1A0D", fg = "#00FF00" },
					CursorLine = { bg = "#0D1A0D" },
					CursorLineNr = { fg = "#66FF66", bold = true },
					LineNr = { fg = "#339933" },
					Visual = { bg = "#00FF00", fg = "#000000" },
					Search = { bg = "#FF9900", fg = "#000000" },
					IncSearch = { bg = "#FFCC33", fg = "#000000" },
					Cursor = { bg = "#66FF66", fg = "#000000" },
					StatusLine = { bg = "#0D1A0D", fg = "#00FF00" },
					StatusLineNC = { bg = "#000000", fg = "#339933" },
					Pmenu = { bg = "#0D1A0D", fg = "#00FF00" },
					PmenuSel = { bg = "#00FF00", fg = "#000000" },
					PmenuSbar = { bg = "#0D1A0D" },
					PmenuThumb = { bg = "#00FF00" },
					Comment = { fg = "#339933", italic = true },
					String = { fg = "#FFCC33" },
					Keyword = { fg = "#33FFAA" },
					Function = { fg = "#66FF66" },
					Type = { fg = "#FF9900" },
					Constant = { fg = "#FFCC33" },
					Number = { fg = "#FF9900" },
					DiagnosticError = { fg = "#FF9900" },
					DiagnosticWarn = { fg = "#FFCC33" },
					DiagnosticInfo = { fg = "#00FF00" },
					DiagnosticHint = { fg = "#22BB55" },
					WinSeparator = { fg = "#339933", bg = "#000000" },
					SignColumn = { bg = "#000000" },
					EndOfBuffer = { fg = "#000000" },
				},
			})
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "hackerman",
		},
	},
}
