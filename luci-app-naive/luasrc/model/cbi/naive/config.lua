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

local log_view = s:option(DummyValue, "_log_view", "实时日志")
log_view.rawhtml = true

function log_view.cfgvalue()
  local log_url = dispatcher.build_url("admin", "services", "naive", "log")

  return string.format([[
<div class="naive-log-panel">
  <div style="margin-bottom:8px; display:flex; gap:8px; flex-wrap:wrap; align-items:center;">
    <button class="btn cbi-button cbi-button-action" type="button" id="naive-log-refresh">立即刷新</button>
    <button class="btn cbi-button" type="button" id="naive-log-toggle">暂停刷新</button>
    <button class="btn cbi-button cbi-button-reset" type="button" id="naive-log-clear">清屏</button>
    <label style="display:inline-flex; gap:6px; align-items:center;">
      <input type="checkbox" id="naive-log-autorefresh" checked="checked" />
      <span>自动刷新</span>
    </label>
    <span id="naive-log-status" style="color:#666;">准备就绪</span>
  </div>
  <textarea id="naive-log-output" readonly="readonly" wrap="off" style="width:100%%; min-height:320px; font-family:monospace; white-space:pre; overflow:auto;"></textarea>
</div>
<script type="text/javascript">
(function() {
  var logUrl = %q;
  var output = document.getElementById('naive-log-output');
  var status = document.getElementById('naive-log-status');
  var refreshButton = document.getElementById('naive-log-refresh');
  var toggleButton = document.getElementById('naive-log-toggle');
  var clearButton = document.getElementById('naive-log-clear');
  var autoRefresh = document.getElementById('naive-log-autorefresh');
  var paused = false;
  var timer = null;
  var intervalMs = 3000;

  function setStatus(message) {
    status.textContent = message;
  }

  function schedule() {
    if (timer) {
      window.clearTimeout(timer);
      timer = null;
    }

    if (!paused && autoRefresh.checked) {
      timer = window.setTimeout(fetchLogs, intervalMs);
    }
  }

  function fetchLogs() {
    if (paused) {
      setStatus('已暂停');
      schedule();
      return;
    }

    setStatus('正在刷新...');

    var xhr = new XMLHttpRequest();
    xhr.open('GET', logUrl, true);
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== 4) {
        return;
      }

      if (xhr.status >= 200 && xhr.status < 300) {
        output.value = xhr.responseText || '暂无日志';
        output.scrollTop = output.scrollHeight;
        setStatus(autoRefresh.checked ? '自动刷新中' : '已刷新');
      } else {
        setStatus('日志读取失败');
      }

      schedule();
    };
    xhr.send(null);
  }

  refreshButton.addEventListener('click', function() {
    fetchLogs();
  });

  toggleButton.addEventListener('click', function() {
    paused = !paused;
    toggleButton.textContent = paused ? '继续刷新' : '暂停刷新';
    setStatus(paused ? '已暂停' : '自动刷新中');
    schedule();

    if (!paused) {
      fetchLogs();
    }
  });

  clearButton.addEventListener('click', function() {
    output.value = '';
    setStatus(paused ? '已暂停，日志已清屏' : '日志已清屏');
  });

  autoRefresh.addEventListener('change', function() {
    if (!autoRefresh.checked) {
      setStatus(paused ? '已暂停' : '自动刷新已关闭');
      schedule();
      return;
    }

    if (!paused) {
      fetchLogs();
    }
  });

  fetchLogs();
})();
</script>
]], log_url)
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
