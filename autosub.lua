-- add this to your input.conf to change the key to download the subtitles
-- keyname script_binding auto_load_subs
local utils = require 'mp.utils'
function load_sub_fn()
    subl = "/usr/local/bin/subliminal" --use 'which subliminal' to find the path
    mp.msg.info("Searching subtitle")
    t = {}
    t.args = {subl, "-q", "-s", "-l", "en", "--", mp.get_property("path")}
    res = utils.subprocess(t)
    if res.status == 0 then
        mp.commandv("rescan_external_files", "reselect") 
        mp.msg.info("Subtitle download succeeded")
    else
        mp.msg.warn("Subtitle download failed")
    end
end

mp.add_key_binding("b", "auto_load_subs", load_sub_fn)