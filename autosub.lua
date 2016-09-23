-- requires subliminal, version 1.0 or newer
-- default keybinding: b
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_load_subs

local utils = require 'mp.utils'

------------------------------------------------------------------------
-- USER CONFIG ---------------------------------------------------------
------------------------------------------------------------------------
-- SUBL
--     If subliminal is not in PATH, provide full path to the executable
--     instead.
-- TMPDIR
--     The directory to stuff the subtitles into if the media being
--     played is a stream. If the directory doesn't exists, it will be
--     created. The string must end with a slash character.
--     If the media being played is a local file, the subtitles will be
--     saved in the directory where the file is.
-- LANGS
--     The languages to download the subtitles in.
-------------------------------------------------------------------------
local SUBL = "subliminal"
local TMPDIR = os.getenv("HOME") .. "/.cache/mpv/autosub/"
local LANGS = {"en", "it"}
-------------------------------------------------------------------------


function print_msg(msg, level)
	mp.osd_message(msg)
	if level == "info" then
		mp.msg.info(msg)
	elseif level == "warning" then
		mp.msg.warn(msg)
	end
end


function execute_command(args)
	local command = {}
	command.args = args
	return utils.subprocess(command)
end


function prepare_tmpdir(tmpdir, title)
	local args = {"mkdir", "-p", tmpdir .. title}
	local res = execute_command(args)
	if res.status ~= 0 then error() end
end


function download_subtitles(subliminal_executable, media_source, media_title, langs, tmpdir)
	local args = {subliminal_executable, "download"}
	if media_source == "stream" then
		table.insert(args, "-d")
		table.insert(args, tmpdir .. media_title)
	end
	for idx, lang in ipairs(langs) do
		table.insert(args, "-l")
		table.insert(args, lang)
	end
	table.insert(args, media_title)
	return execute_command(args)
end


function iter_files(dir)
	local files = utils.readdir(dir, "files")
	local file = table.remove(files)
	return function()
		while file do
			local ret = file
			file = table.remove(files)
			return ret
		end
	end
end


function load_sub_fn()
	local source = "file"
	local title = mp.get_property("path")

	-- Check if we're dealing with a stream, not a file (there's
	-- probably a better way to discriminate between those two).
	if title == nil or title:find("http://") == 1
			or title:find("https://") == 1 then
		title = mp.get_property("media-title")
		source = "stream"
		prepare_tmpdir(TMPDIR, title)
	end

	local msg = string.format("Searching for subtitles (%s) for %s",
	table.concat(LANGS, ", "), title)
	print_msg(msg, "info")

	local result = download_subtitles(SUBL, source, title, LANGS, TMPDIR)

	if result.status == 0 then
		if source == "file" then
			mp.commandv("rescan_external_files", "reselect")
		elseif source == "stream" then
			for file in iter_files(TMPDIR .. title) do
				mp.commandv("sub-add", TMPDIR .. title .. "/" .. file)
			end
		end
		msg = string.format("Subtitle download successful.\nSubliminal" ..
		" says:\n %s ", result.stdout)
		print_msg(msg, "info")
	else
		msg = string.format("Subtitle download failed!\nSubliminal" ..
		" says\n: %s ", result.stdout)
		print_msg(msg, "warning")
	end
end


mp.add_key_binding("b", "auto_load_subs", load_sub_fn)
