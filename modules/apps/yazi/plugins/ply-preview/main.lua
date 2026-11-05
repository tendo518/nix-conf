--- @since 26.9.1
-- Render .ply meshes and point clouds as image previews.
--
-- The heavy lifting lives in render.py. The plugin asks that helper to write a
-- PNG into Yazi's preview cache, then hands the PNG to Yazi's image adapter.
-- Scrolling up/down rotates the model in 15 degree steps.

local M = {}

local RENDERER = os.getenv("YAZI_PLY_RENDERER") or "yazi-ply-render"

local function positive(value)
	return type(value) == "number" and value > 0
end

local function preview_pixels(area)
	if not area then
		return nil, nil
	end

	local ok, cw, ch = pcall(function()
		if rt and rt.term and rt.term.cell_size then
			return rt.term.cell_size()
		end
		return nil, nil
	end)
	if ok and positive(cw) and positive(ch) then
		return math.floor(area.w * cw), math.floor(area.h * ch)
	end

	local ok2, pw, ph = pcall(function()
		if rt and rt.preview then
			return rt.preview.max_width, rt.preview.max_height
		end
		return nil, nil
	end)
	if ok2 and positive(pw) and positive(ph) then
		return math.floor(pw), math.floor(ph)
	end
	return nil, nil
end

local function job_skip(job)
	if job and type(job.skip) == "number" then
		return job.skip
	end
	return 0
end

local function exists(url)
	-- Yazi 26.9.x exposes fs.cha; newer versions renamed it to fs.stat.
	local stat = fs.cha or fs.stat
	return stat ~= nil and stat(url) ~= nil
end

function M:preload(job)
	local cache = ya.file_cache(job)
	if not cache then
		return false, Err("Failed to create a preview cache path")
	end
	if exists(cache) then
		return true
	end

	local width, height = preview_pixels(job.area)
	local yaw = job_skip(job) * 15
	local cmd = Command(RENDERER):arg({
		tostring(job.file.path),
		tostring(cache),
		"--width",
		tostring(width or 1000),
		"--height",
		tostring(height or 800),
		"--yaw",
		tostring(yaw),
	})

	local output, err = cmd:output()
	if not output then
		return false, Err("Failed to start `%s`, error: %s", RENDERER, err)
	elseif not output.status.success then
		local stderr = (output.stderr or ""):gsub("%s+$", "")
		return false, Err("PLY preview failed: %s", stderr)
	end
	return true
end

function M:peek(job)
	local cache = ya.file_cache(job)
	if not cache then
		return ya.preview_widget(job, Err("Failed to create a preview cache path"))
	end

	local ok, err = self:preload(job)
	if not ok or err then
		return ya.preview_widget(job, err)
	end

	local _, show_err = ya.image_show(cache, job.area)
	ya.preview_widget(job, show_err)
end

function M:seek(job)
	-- Yazi 26.9.x uses cx.active; newer versions use cx.tab.
	local current = cx.active and cx.active.current or cx.tab and cx.tab.current
	local preview = cx.active and cx.active.preview or cx.tab and cx.tab.preview
	local hovered = current and current.hovered
	if not hovered or hovered.url ~= job.file.url then
		return
	end

	local step = ya.clamp(-1, job.units or 0, 1)
	local base = preview and preview.skip or job_skip(job)
	ya.emit("peek", { math.max(0, base + step), only_if = job.file.url, scope = job.scope })
end

local function default_spot(job)
	local ok, result = pcall(function()
		return require("file"):spot(job)
	end)
	if ok then
		return result
	end
end

function M:spot(job)
	local ok = pcall(function()
		local rows = {
			ui.Row({ "PLY Preview" }):style(ui.Style():fg("green")),
			ui.Row({ "  Rotate:", "scroll up/down" }),
			ui.Row({ "  Renderer:", RENDERER }),
			ui.Row({}),
		}
		ya.spot_table(
			job,
			ui.Table(ya.list_merge(rows, require("file"):spot_base(job)))
				:area(ui.Pos({ "center", w = 60, h = 16 }))
				:row(job_skip(job))
				:row(1)
				:col(1)
				:col_style(th.spot.tbl_col)
				:cell_style(th.spot.tbl_cell)
				:widths({ ui.Constraint.Length(14), ui.Constraint.Fill(1) })
		)
	end)
	if not ok then
		return default_spot(job)
	end
end

return M
