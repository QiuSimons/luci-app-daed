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

enable = s:option(Flag, "subscribe_auto_update", translate("Enable Auto Subscribe Update"))
enable.rmempty = false

o = s:option(Value, "daed_username", translate("Username"))
o.default = Username
o.password = true
o:depends('subscribe_auto_update', '1')

o = s:option(Value, "daed_password", translate("Password"))
o.default = Password
o.password = true
o:depends('subscribe_auto_update', '1')

o = s:option(ListValue, "subscribe_update_week_time", translate("Update Cycle"))
o:value("*", translate("Every Day"))
o:value("1", translate("Every Monday"))
o:value("2", translate("Every Tuesday"))
o:value("3", translate("Every Wednesday"))
o:value("4", translate("Every Thursday"))
o:value("5", translate("Every Friday"))
o:value("6", translate("Every Saturday"))
o:value("7", translate("Every Sunday"))
o.default = "*"
o:depends('subscribe_auto_update', '1')

update_time = s:option(ListValue, "subscribe_update_day_time", translate("Update Time (Every Day)"))
for t = 0, 23 do
  update_time:value(t, t..":00")
end
update_time.default = 0
update_time:depends('subscribe_auto_update', '1')

o = s:option(Value, "log_maxbackups", translate("Logfile retention count"))
o.default = 1

o = s:option(Value, "log_maxsize", translate("Logfile Max Size (MB)"))
o.default = 5

o = s:option(Value, "listen_addr",translate("Set the DAED listen address"))
o.default = '0.0.0.0:2023'

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/daed restart")
end

return m
