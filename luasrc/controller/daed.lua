module("luci.controller.daed", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/daed") then
		return
	end

	entry({"admin",  "services", "daed"}, alias("admin", "services", "daed", "setting"),_("DAED"), 58).dependent = true
	entry({"admin", "services", "daed", "setting"}, cbi("daed"), _("Base Setting"), 20).leaf=true
	entry({"admin",  "services", "daed", "daed"}, template("daed"), _("DAED"), 30).leaf = true
	entry({"admin", "services", "daed_status"}, call("act_status"))
end

function act_status()
	local sys  = require "luci.sys"
	local e = { }
	e.running = sys.call("pidof daed >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
