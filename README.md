# luci-app-naive

一个用于 OpenWrt 的 LuCI 管理界面，用来配置和管理手动安装的 NaiveProxy 客户端。

This repository provides an OpenWrt LuCI application for managing a manually installed NaiveProxy client. It does not require the `naiveproxy` package from OpenWrt feeds.

## Highlights

- 中文 LuCI 界面
- 支持自定义核心二进制路径
- 标准 `procd` 服务管理
- 运行时自动生成 `config.json`
- LuCI 页面内实时日志
- 支持自动刷新、暂停刷新、清屏
- 升级安装时保留 `/etc/config/naive`

## 适用场景

如果你不想安装 OpenWrt 官方或第三方的 `naiveproxy` 软件包，而是希望自己上传 NaiveProxy 二进制文件到路由器，例如：

- `/usr/bin/naive`
- `/root/naiveproxy/naive`

那么这个 LuCI 插件就是为这种方式准备的。

## 仓库结构

- `luci-app-naive/Makefile`
  OpenWrt 包定义
- `luci-app-naive/luasrc/controller/naive.lua`
  LuCI 控制器和日志接口
- `luci-app-naive/luasrc/model/cbi/naive/config.lua`
  LuCI 配置页面
- `luci-app-naive/root/etc/init.d/naive`
  `procd` 服务脚本
- `luci-app-naive/root/etc/config/naive`
  默认 UCI 配置

## 功能说明

当前版本支持：

- 配置本地监听地址、端口和代理类型
- 配置上游协议、服务器、用户名、密码
- 指定 NaiveProxy 二进制文件路径
- 传递额外启动参数
- 查看核心文件是否存在且可执行
- 在页面内查看实时日志

日志面板支持：

- 立即刷新
- 自动刷新
- 暂停/继续刷新
- 清屏

## 编译方法

把本仓库中的 `luci-app-naive` 目录复制到 OpenWrt 源码树的 `package/` 下：

```sh
cp -r luci-app-naive /path/to/openwrt/package/
cd /path/to/openwrt
make menuconfig
make package/luci-app-naive/compile V=s
```

生成的 `ipk` 一般在：

```sh
bin/packages/<target>/<subtarget>/base/luci-app-naive_*.ipk
```

## 安装方法

安装 `ipk` 后，把你的 NaiveProxy 二进制上传到路由器并赋予执行权限，例如：

```sh
scp naive root@router:/root/naiveproxy/naive
ssh root@router chmod +x /root/naiveproxy/naive
```

然后进入 LuCI：

```text
服务 -> Naive 代理
```

需要重点配置：

- 二进制路径
- 本地监听地址
- 本地监听端口
- 上游协议
- 服务器域名
- 用户名和密码
- 额外参数

## 升级行为

从 `V1.1` 开始，包安装时会保留已有的：

```text
/etc/config/naive
```

这意味着升级新版本后，不需要每次重新填写 LuCI 配置。

## 日志说明

页面中的日志来自系统日志：

```sh
logread -e naive
```

它不是去读取某个固定目录下的日志文件。

服务启动时会额外写入这些日志，方便确认是否用了你指定的核心路径：

- `starting binary: ...`
- `generated runtime config: ...`

## 注意事项

- 如果用户名或密码包含 URL 保留字符，请先进行 URL 编码
- `extra_args` 当前按空格拆分，适合简单参数
- 运行时配置文件生成在 `/var/etc/naive/config.json`
- 如果你把核心放在 `/root/naiveproxy/naive`，记得同时在 LuCI 中把“二进制路径”改成对应路径

## 版本

- `V1.0`
  初始正式可用版本
- `V1.1`
  增加实时日志、配置保留和更清晰的启动日志

详细变更见 [CHANGELOG.md](CHANGELOG.md)。
