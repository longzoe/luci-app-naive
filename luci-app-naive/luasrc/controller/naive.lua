module("luci.controller.naive", package.seeall)

function index()
  local fs = require("nixio.fs")

  if not fs.access("/etc/config/naive") then
    return
  end

  entry({"admin", "services", "naive"}, cbi("naive/config"), "Naive 代理", 60).dependent = true
  entry({"admin", "services", "naive", "log"}, call("action_log"), "日志", 61).leaf = true
end

function action_log()
  local http = require("luci.http")
  local sys = require("luci.sys")

  http.prepare_content("text/plain; charset=utf-8")
  http.write(sys.exec("logread -e naive 2>/dev/null | tail -n 200"))
end
