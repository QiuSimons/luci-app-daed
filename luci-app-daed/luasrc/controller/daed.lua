local sys  = require "luci.sys"
local http = require "luci.http"

module("luci.controller.daed", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/daed") then
		return
	end

	entry({"admin",  "services", "daed"}, alias("admin", "services", "daed", "setting"),_("DAED"), 58).dependent = true
	entry({"admin", "services", "daed", "setting"}, cbi("daed/basic"), _("Base Setting"), 1).leaf=true
	entry({"admin",  "services", "daed", "daed"}, template("daed/daed"), _("Dashboard"), 2).leaf = true
	entry({"admin", "services", "daed", "log"}, cbi("daed/log"), _("Logs"), 3).leaf = true
	entry({"admin", "services", "daed_status"}, call("act_status"))
	entry({"admin", "services", "daed", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "daed", "clear_log"}, call("clear_log")).leaf = true
end

function act_status()
	local sys  = require "luci.sys"
	local e = { }
	e.running = sys.call("pidof daed >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	http.write(sys.exec("cat /var/log/daed/daed.log"))
end

function clear_log()
	sys.call("true > /var/log/daed/daed.log")
end
