local m, s ,o

m = Map("daed")
m.title = translate("DAED")
m.description = translate("DAE is a Linux high-performance transparent proxy solution based on eBPF, And DAED is a modern dashboard for dae.")

m:section(SimpleSection).template = "daed/daed_status"

s = m:section(TypedSection, "daed", translate("Global Settings"))
s.addremove = false
s.anonymous = true

o = s:option(Flag,"enabled",translate("Enable"))
o.default = 0

o = s:option(Value, "log_maxbackups", translate("Logfile retention count"))
o.default = 1

o = s:option(Value, "log_maxsize", translate("Logfile Max Size (MB)"))
o.default = 5

o = s:option(Value, "listen_addr",translate("Set the DAED listen address"))
o.default = '0.0.0.0:2023'

o = s:option(Value, "dashboard_port", translate("Dashboard Access Port"))
o.placeholder = translate("Leave empty to use listen port")
o.datatype = "range(1,65535)"
o.description = translate("For reverse proxy scenarios, leave empty to use the port from listen address")

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/daed restart")
end

return m