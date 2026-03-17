local sys = require("luci.sys")
local dispatcher = require("luci.dispatcher")
local util = require("luci.util")
local fs = require("nixio.fs")
local uci = require("luci.model.uci").cursor()

local m = Map("naive", "NaiveProxy", "配置本地 NaiveProxy 客户端，并以 OpenWrt 服务方式管理。")

function m.on_after_commit(self)
  local enabled = uci:get_bool("naive", "@naive[0]", "enabled")

  if enabled then
    sys.call("/etc/init.d/naive restart >/dev/null 2>&1")
  else
    sys.call("/etc/init.d/naive stop >/dev/null 2>&1")
  end
end

local s = m:section(TypedSection, "naive", "客户端设置")
s.anonymous = true
s.addremove = false

local status = s:option(DummyValue, "_status", "服务状态")
status.rawhtml = true

function status.cfgvalue()
  if sys.call("/etc/init.d/naive status >/dev/null 2>&1") == 0 then
    return "<strong style=\"color:#28a745\">运行中</strong>"
  end

  return "<strong style=\"color:#d9534f\">已停止</strong>"
end

local binary = s:option(DummyValue, "_binary_status", "核心状态")
binary.rawhtml = true

function binary.cfgvalue()
  local path = uci:get("naive", "@naive[0]", "binary_path") or "/usr/bin/naive"

  if fs.access(path, "x") then
    return string.format(
      "<strong style=\"color:#28a745\">%s</strong><br /><span>%s</span>",
      "可用",
      util.pcdata(path)
    )
  end

  return string.format(
    "<strong style=\"color:#d9534f\">%s</strong><br /><span>%s</span>",
    "缺失或不可执行",
    util.pcdata(path)
  )
end

local logs = s:option(DummyValue, "_logs", "最近日志")
logs.rawhtml = true

function logs.cfgvalue()
  return string.format(
    "<a class=\"btn cbi-button cbi-button-action\" href=\"%s\" target=\"_blank\" rel=\"noreferrer\">%s</a>",
    dispatcher.build_url("admin", "services", "naive", "log"),
    "打开日志"
  )
end

local start = s:option(Button, "_start", "启动服务")
start.inputstyle = "apply"

function start.write()
  sys.call("/etc/init.d/naive start >/dev/null 2>&1")
end

local stop = s:option(Button, "_stop", "停止服务")
stop.inputstyle = "reset"

function stop.write()
  sys.call("/etc/init.d/naive stop >/dev/null 2>&1")
end

local restart = s:option(Button, "_restart", "重启服务")
restart.inputstyle = "reload"

function restart.write()
  sys.call("/etc/init.d/naive restart >/dev/null 2>&1")
end

local o

o = s:option(Flag, "enabled", "启用")
o.rmempty = false
o.default = o.disabled

o = s:option(Value, "binary_path", "二进制路径")
o.datatype = "file"
o.default = "/usr/bin/naive"

o = s:option(ListValue, "listen_type", "本地代理类型")
o:value("socks", "SOCKS5")
o:value("http", "HTTP")
o.default = "socks"

o = s:option(Value, "listen_addr", "本地监听地址")
o.datatype = "ipaddr"
o.default = "127.0.0.1"

o = s:option(Value, "listen_port", "本地监听端口")
o.datatype = "port"
o.default = 1080

o = s:option(ListValue, "proxy_protocol", "上游协议")
o:value("https", "HTTPS")
o:value("quic", "QUIC")
o.default = "https"

o = s:option(Value, "server", "服务器域名")
o.datatype = "host"
o.default = "example.com"

o = s:option(Value, "server_port", "服务器端口")
o.datatype = "port"
o.default = 443

o = s:option(Value, "username", "用户名")
o.maxlength = 128

o = s:option(Value, "password", "密码")
o.password = true
o.maxlength = 128

o = s:option(Value, "extra_args", "额外参数")
o.placeholder = "--log"

local note = s:option(DummyValue, "_note", "说明")
note.rawhtml = true
note.default = "请先手动将 NaiveProxy 二进制上传到路由器，并赋予可执行权限，再把“二进制路径”指向它。服务会在运行时生成 config.json。“额外参数”会按空格拆分后追加到命令行。如果用户名或密码包含 URL 保留字符，请先自行进行 URL 编码。"

return m
