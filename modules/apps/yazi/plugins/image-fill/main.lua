--- @since 25.12.29
-- Upscale images to fit the preview area.
--
-- Based on stellarjmr/image-fit.yazi (MIT), adapted to use ImageMagick `magick`
-- instead of macOS-only `sips` so it works on both macOS and NixOS/Linux.
--
-- yazi's built-in ya.image_show only DOWNSCALES, so small images render at
-- their natural size and don't fill the pane. This previewer resizes the image
-- (up or down) to the preview pane's pixel size with `magick`, then shows it.
-- Pane pixels come from rt.term.cell_size() (terminal cell size x area cells),
-- falling back to rt.preview.max_width/max_height when cell size is unavailable.
-- Any failure falls back to yazi's built-in image renderer.

local M = {}

local MAGICK = "magick"

-- Path of the temp file from the most recent peek. Module-level so it
-- persists across peek() calls (the module is loaded once). Used to remove
-- the previous temp at the start of the next peek, bounding temps to ~1.
local last_temp

local function positive_number(value)
	return type(value) == "number" and value > 0
end

local function area_size(area)
	local ok, w, h = pcall(function()
		if area then
			return area.w, area.h
		end
		return nil, nil
	end)
	if ok then
		return w, h
	end
	return nil, nil
end

local function image_size(info)
	local ok, w, h = pcall(function()
		if info then
			return info.w, info.h
		end
		return nil, nil
	end)
	if ok then
		return w, h
	end
	return nil, nil
end

local function status_success(status)
	local ok, success = pcall(function()
		if status then
			return status.success
		end
		return nil
	end)
	return ok and success == true
end

local function preview_size()
	local ok, max_w, max_h = pcall(function()
		local preview = rt and rt.preview
		if preview then
			return preview.max_width, preview.max_height
		end
		return nil, nil
	end)
	if ok then
		return max_w, max_h
	end
	return nil, nil
end

local function max_pixels(area)
	local area_w, area_h = area_size(area)
	if not positive_number(area_w) or not positive_number(area_h) then
		return nil, nil
	end

	local ok, cw, ch = pcall(function()
		if rt and rt.term and rt.term.cell_size then
			return rt.term.cell_size()
		end
		return nil, nil
	end)
	if not ok then
		cw, ch = nil, nil
	end
	if positive_number(cw) and positive_number(ch) then
		return math.max(1, math.floor(area_w * cw)), math.max(1, math.floor(area_h * ch))
	end

	local preview_w, preview_h = preview_size()
	if positive_number(preview_w) and positive_number(preview_h) then
		return preview_w, preview_h
	end
	return nil, nil
end

local function fit_size(info, max_w, max_h)
	if not positive_number(max_w) or not positive_number(max_h) then
		return nil, nil
	end

	local info_w, info_h = image_size(info)
	if not positive_number(info_w) or not positive_number(info_h) then
		return nil, nil
	end

	local scale = math.min(max_w / info_w, max_h / info_h)
	if scale <= 0 then
		return max_w, max_h
	end

	return math.max(1, math.floor(info_w * scale)), math.max(1, math.floor(info_h * scale))
end

local function safe_image_info(url)
	local ok, info = pcall(function()
		return ya.image_info(url)
	end)
	if ok and type(info) == "table" then
		return info
	end
	return nil
end

local function file_url(job)
	local ok, url = pcall(function()
		if job and job.file then
			return job.file.url
		end
		return nil
	end)
	if ok then
		return url
	end
	return nil
end

local function job_area(job)
	local ok, area = pcall(function()
		if job then
			return job.area
		end
		return nil
	end)
	if ok then
		return area
	end
	return nil
end

local function job_skip(job)
	local ok, skip = pcall(function()
		if job then
			return job.skip
		end
		return nil
	end)
	if ok then
		return skip
	end
	return nil
end

local function show_image(job, url)
	local ok, shown, err = pcall(function()
		return ya.image_show(url, job_area(job))
	end)
	if not ok then
		err = shown
	end
	pcall(function()
		ya.preview_widget(job, err)
	end)
end

local function show_original(job)
	show_image(job, file_url(job))
end

local function temp_png()
	local ok, name = pcall(function()
		return os.tmpname()
	end)
	if ok and type(name) == "string" and name ~= "" then
		return name .. ".png"
	end
	return nil
end

local function preview_url(path)
	local ok, url = pcall(function()
		return Url(path)
	end)
	if ok and url then
		return url
	end
	return nil
end

local function source_path(url)
	local ok, path = pcall(function()
		return tostring(url)
	end)
	if ok and type(path) == "string" and path ~= "" then
		return path
	end
	return nil
end

local function resize_image(source, w, h, tmp)
	local ok, status = pcall(function()
		return Command(MAGICK):arg({
			tostring(source),
			"-resize",
			string.format("%dx%d", w, h),
			"PNG:" .. tmp,
		}):status()
	end)
	if ok then
		return status
	end
	return nil
end

function M:peek(job)
	-- Remove the temp file from the previous peek. Its image is already on
	-- the terminal (or that peek was cancelled), so the file is no longer
	-- needed. This bounds temp files to at most one at a time, so scrolling
	-- through hundreds of images does not accumulate /tmp files.
	if last_temp then
		pcall(os.remove, last_temp)
		last_temp = nil
	end

	local url = file_url(job)
	if not url then
		return show_original(job)
	end
	local info = safe_image_info(url)
	if not info then
		return show_original(job)
	end

	local max_w, max_h = max_pixels(job_area(job))
	local w, h = fit_size(info, max_w, max_h)
	if not w or not h then
		return show_original(job)
	end

	local source = source_path(url)
	if not source then
		return show_original(job)
	end

	local tmp = temp_png()
	if not tmp then
		return show_original(job)
	end
	last_temp = tmp

	local status = resize_image(source, w, h, tmp)
	if not status or not status_success(status) then
		pcall(os.remove, tmp)
		last_temp = nil
		return show_original(job)
	end

	local resized = preview_url(tmp)
	if not resized then
		pcall(os.remove, tmp)
		last_temp = nil
		return show_original(job)
	end
	show_image(job, resized)
	-- tmp is intentionally kept (in last_temp) until the next peek removes
	-- it: yazi may re-read it while this file is still the preview.
end

function M:seek() end

local function default_spot(job)
	local ok, result = pcall(function()
		return require("file"):spot(job)
	end)
	if ok then
		return result
	end
end

function M:spot(job)
	local url = file_url(job)
	if not url then
		return default_spot(job)
	end
	local info = safe_image_info(url)
	local info_w, info_h = image_size(info)
	if not info or not positive_number(info_w) or not positive_number(info_h) then
		return default_spot(job)
	end

	local ok = pcall(function()
		local rows = {
			ui.Row({ "Image" }):style(ui.Style():fg("green")),
			ui.Row { "  Format:", tostring(info.format) },
			ui.Row { "  Size:", string.format("%dx%d", info_w, info_h) },
			ui.Row { "  Color:", tostring(info.color) },
			ui.Row {},
		}

		ya.spot_table(
			job,
			ui.Table(ya.list_merge(rows, require("file"):spot_base(job)))
				:area(ui.Pos { "center", w = 60, h = 20 })
				:row(job_skip(job))
				:row(1)
				:col(1)
				:col_style(th.spot.tbl_col)
				:cell_style(th.spot.tbl_cell)
				:widths { ui.Constraint.Length(14), ui.Constraint.Fill(1) }
		)
	end)
	if not ok then
		return default_spot(job)
	end
end

return M
