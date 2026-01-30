# Hammerspoon-scripts

个人的 Hammerspoon 配置，聚合了常用的 Finder 小工具、自动切换网络位置、以及窗口管理快捷键。将 `init.lua` 放到 `~/.hammerspoon/` 后重载即可。

## 快速使用
- 安装 Hammerspoon 并在偏好设置中允许辅助功能与定位权限（脚本会读取 Wi‑Fi SSID 与系统网络位置）。
- 将本仓库的 `init.lua` 覆盖/软链到 `~/.hammerspoon/init.lua`，在菜单栏 Hammerspoon 选择 Reload。
- 可根据需要修改脚本里的映射（如 Wi‑Fi SSID 与 macOS Location 名称、按键等）。

## 功能与快捷键
### Finder 实用工具
- `⌥ + N`：在当前 Finder 目录新建空白 TXT 文件，若重名自动递增。
- `⌥ + Z`：将当前选中的文件夹打包为 ZIP，输出到 `~/Downloads/`，自动避免重名并完成后在 Finder 中选中。
- `⌥ + D`：将 Finder 选中文件移动到废纸篓（模拟 `⌘ + Delete`）。

### 自动切换网络位置
- 根据 Wi‑Fi SSID 映射到 macOS 网络 Location（脚本默认映射：`xxxx → office`，`xxxx → home`，其它 → `Automatic`）。
- 连接 Wi‑Fi 时自动执行 `scselect` 切换，并弹窗提示当前生效的位置。
- 如需调整，编辑脚本中的 `locationMap` 或 `defaultLocation`，确保对应的 Location 已在系统网络设置里创建。

### 窗口管理（Hyper = `⌥ + ⌘`）
- `Hyper + Return`：窗口化全屏；再次触发切换为居中半宽。
- `Hyper + Left/Right`：窗口占屏幕的左/右 2/3。
- `Hyper + Up/Down`：窗口占屏幕的左/右 1/3（便于三列布局）。
- `Hyper + N`：将当前窗口移到下一个显示器。
- `Hyper + R`：重载 Hammerspoon 配置。

### 其它
- `⌥ + T`：启动或激活 iTerm2。

## 自定义提示
- 需要使用不同键位时，可直接修改 `hs.hotkey.bind` 的修饰键与主键。
- 压缩功能依赖系统自带的 `zip` 命令，默认输出位置为 `~/Downloads/`，可在脚本中调整。
