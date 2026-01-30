-- 将Hammerspoon 加入到定位服务中
print(hs.location.get())

-- 在当前 Finder 窗口中新建 TXT 文件
function newTxtInFinder()
    local finder = hs.appfinder.appFromName("Finder")
    if not finder then
        hs.alert.show("Finder 未运行")
        return
    end

    -- 获取当前 Finder 目录
    local _, result = hs.osascript.applescript([[
        tell application "Finder"
            if (count of windows) is 0 then
                set thePath to (path to desktop as text)
            else
                set thePath to (POSIX path of (target of front window as alias))
            end if
        end tell
        return thePath
    ]])

    if not result then
        hs.alert.show("无法获取目录")
        return
    end

    -- 新文件完整路径
    local filePath = result .. "新建文本文档.txt"

    -- 如果已经存在，则递增文件名
    local index = 1
    local finalPath = filePath
    while hs.fs.attributes(finalPath) do
        finalPath = result .. string.format("新建文本文档(%d).txt", index)
        index = index + 1
    end

    -- 创建空文件
    local f = io.open(finalPath, "w")
    if f then
        f:write("")
        f:close()
        hs.alert.show("已创建 TXT 文件")
        -- 在 Finder 中选中文件
        hs.osascript.applescript(string.format([[
            tell application "Finder"
                activate
                reveal POSIX file "%s"
            end tell
        ]], finalPath))
    else
        hs.alert.show("创建失败")
    end
end

-- 绑定快捷键，例如：⌥ + N
hs.hotkey.bind({"alt"}, "N", newTxtInFinder)



-- 压缩当前 Finder 选中的文件夹为 ZIP 并移到下载文件夹
function compressSelectedFolder()
    -- 获取 Finder 选中项目
    local ok, selection = hs.osascript.applescript([[
        tell application "Finder"
            if selection is {} then
                return ""
            else
                set theItem to item 1 of (get selection)
                return POSIX path of (theItem as alias)
            end if
        end tell
    ]])

    if not ok or selection == "" then
        hs.alert.show("没有选中任何文件夹")
        return
    end

    -- 判断是否为文件夹
    local attr = hs.fs.attributes(selection)
    if not attr or attr.mode ~= "directory" then
        hs.alert.show("请选择一个文件夹")
        return
    end

    -- 获取目标 ZIP 文件名
    local downloadDir = os.getenv("HOME") .. "/Downloads/"
    local folderName = string.match(selection, "([^/]+)/?$")
    local zipPath = downloadDir .. folderName .. ".zip"

    -- 若同名存在则加编号
    local index = 1
    local finalZipPath = zipPath
    while hs.fs.attributes(finalZipPath) do
        finalZipPath = downloadDir .. folderName .. "(" .. index .. ").zip"
        index = index + 1
    end

    -- 执行 zip 命令
    local cmd = string.format(
        'cd "%s" && zip -r "%s" "%s"',
        string.sub(selection, 1, #selection - #folderName - 1),
        finalZipPath,
        folderName
    )

    hs.task.new("/bin/bash", function()
        hs.alert.show("压缩完成: " .. finalZipPath)
        hs.execute(string.format('open -R "%s"', finalZipPath))
    end, { "-c", cmd }):start()
end

-- 绑定快捷键（例如：⌥ + Z）
hs.hotkey.bind({"alt"}, "Z", compressSelectedFolder)

-- Option + D 将 Finder 选中的文件移入废纸篓
hs.hotkey.bind({"alt"}, "D", function()
    local finder = hs.appfinder.appFromName("Finder")

    -- 确保 Finder 当前为前台
    if not finder then
        hs.alert.show("Finder 未运行")
        return
    end

    finder:activate()

    -- 等 Finder 准备接收按键
    hs.timer.doAfter(0.1, function()
        -- 发送 Command + Delete：移动到废纸篓
        hs.eventtap.keyStroke({"cmd"}, "delete")
    end)
end)

-- WiFi SSID 与 macOS 网络位置的映射
-- TODO 更改下面内容为你的配置
local locationMap = {
    ["WIFI名称1"] = "场景名称1",
    ["WIFI名称2"] = "场景名称1",
    ["WIFI名称3"] = "场景名称1",
    -- ...
}

local defaultLocation = "Automatic"
local lastSSID
local lastSwitchTimestamp = 0


---------------------------------------------------------------------
-- 获取当前 macOS 网络位置
---------------------------------------------------------------------
local function getCurrentLocation()
    local output = hs.execute("scselect")

    -- 逐行查找以 * 开头的行，再从括号中取出名称，避免命中说明文字里的 *
    local current
    for line in output:gmatch("[^\r\n]+") do
        local name = line:match("^%s*%*%s+.-%((.-)%)")
        if name then
            current = name
            break
        end
    end
    return current or "Unknown"
end

---------------------------------------------------------------------
-- 切换网络位置
---------------------------------------------------------------------
local function switchLocation(newLocation)
    local result = hs.execute('scselect "' .. newLocation .. '"')
end

---------------------------------------------------------------------
-- WiFi 变化事件回调
---------------------------------------------------------------------
local function ssidChanged()
    local ssid = hs.wifi.currentNetwork()
    local now = os.time()

    -- 避免同一 SSID 短时间内重复触发
    if ssid == lastSSID and (now - lastSwitchTimestamp) < 2 then
        return
    end
    lastSSID = ssid
    lastSwitchTimestamp = now

    local targetLocation

    if ssid and locationMap[ssid] then
        targetLocation = locationMap[ssid]
    else
        targetLocation = defaultLocation
    end

    -- 执行切换
    switchLocation(targetLocation)

    -- 延时读取切换后的实际位置
    hs.timer.doAfter(0.5, function()
        local loc = getCurrentLocation()
        hs.alert.show("切换网络位置：" .. loc)
    end)
end

---------------------------------------------------------------------
-- 启动 WiFi watcher
---------------------------------------------------------------------
wifiWatcher = hs.wifi.watcher.new(ssidChanged)
wifiWatcher:start()

hs.alert.show("WiFi 自动切换网络位置已启动")  



-- 全局打开 iterm2

hs.hotkey.bind({ "alt" }, "T", function()
  hs.application.launchOrFocus("iTerm")
end)




-- ========== 基础配置 ==========
local hyper = {"alt", "cmd"}

local function moveWindow(unit)
    local win = hs.window.focusedWindow()
    if not win then return end

    local screen = win:screen()
    local frame = screen:frame()

    local newFrame = {
        x = frame.x + frame.w * unit.x,
        y = frame.y + frame.h * unit.y,
        w = frame.w * unit.w,
        h = frame.h * unit.h
    }

    win:setFrame(newFrame)
end

-- ========== 全屏（窗口化） ==========

-- 判断是否窗口化全屏
local function isWindowMaximized(win)
    if not win then return false end

    local f = win:frame()
    local s = win:screen():frame()

    return math.abs(f.x - s.x) < 2
       and math.abs(f.y - s.y) < 2
       and math.abs(f.w - s.w) < 2
       and math.abs(f.h - s.h) < 2
end

hs.hotkey.bind(hyper, "Return", function()
    local win = hs.window.focusedWindow()
    if not win then return end

    local screenFrame = win:screen():frame()

    if isWindowMaximized(win) then
        -- 已经是全屏 → 变成居中 1/2 宽，高度占满
        local w = screenFrame.w * 0.5

        win:setFrame({
            x = screenFrame.x + screenFrame.w * 0.25,
            y = screenFrame.y,
            w = w,
            h = screenFrame.h
        })
    else
        -- 非全屏 → 窗口化全屏
        win:setFrame({
            x = screenFrame.x,
            y = screenFrame.y,
            w = screenFrame.w,
            h = screenFrame.h
        })
    end
end)

-- ========== 三分屏 ==========

-- 左 2/3（Left 在左）
hs.hotkey.bind(hyper, "Left", function()
    moveWindow({x=0, y=0, w=2/3, h=1})
end)

-- 右 2/3（Right 在右）
hs.hotkey.bind(hyper, "Right", function()
    moveWindow({x=1/3, y=0, w=2/3, h=1})
end)

hs.hotkey.bind(hyper, "Up", function()
    moveWindow({x=0, y=0, w=1/3, h=1})
end)

hs.hotkey.bind(hyper, "Down", function()
    moveWindow({x=2/3, y=0, w=1/3, h=1})
end)



-- ========== 移动到下一个屏幕 ==========
hs.hotkey.bind(hyper, "N", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    win:moveToScreen(win:screen():next())
end)



-- ========== 自动重载 ==========
hs.hotkey.bind(hyper, "R", function()
    hs.reload()
end)

hs.alert.show("Hammerspoon Window Manager Loaded")