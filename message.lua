if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
    task.wait(0.5)
    player = Players.LocalPlayer
end

player:WaitForChild("Data", 9e9)
player.Data:WaitForChild("Level", 9e9)

-- [Cấu hình người dùng]
local WebhookURL = getgenv().urlwhscrolls
local UpdateInterval = getgenv().timechscrolls or 60
local ConfigOwner = "LÊ VÕ BÁ ANH"

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local FileName = "LeviID_" .. player.Name .. ".txt"
local MessageID = nil 

if isfile and isfile(FileName) then
    MessageID = readfile(FileName)
end

local startTime = os.time()
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local function Format(n)
    return tostring(n):reverse():gsub("...","%0,",(#tostring(n)-1)/3):reverse()
end

-- [NÂNG CẤP]: Thu thập túi đồ siêu an toàn
local function GetInventoryData()
    local inventory = {}
    local success, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    
    if success and type(inv) == "table" then
        for _, v in pairs(inv) do 
            if type(v) == "table" and v.Name then
                -- Lọc sạch các khoảng trắng ẩn (nếu có) để không bị lỗi không khớp tên
                local itemName = tostring(v.Name):match("^%s*(.-)%s*$")
                -- Ưu tiên v.Count, nếu game đổi thành v.Value thì vẫn lấy được
                local itemCount = v.Count or v.Value or 1
                inventory[itemName] = itemCount
            end
        end
    else
        -- Báo lỗi ra F9 nếu executor không thể gửi Request lấy túi đồ
        warn("⚠️ [Hệ thống BaAnh] Lỗi đọc túi đồ hoặc Executor không hỗ trợ: ", tostring(inv))
    end
    return inventory
end

local function GetUptime()
    local totalSeconds = os.time() - startTime
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function Send()
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    local ping = 0
    pcall(function()
        -- Phương pháp lấy Ping an toàn nhất cho mọi Executor
        local pingStr = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        ping = tonumber(string.match(pingStr, "%d+")) or 0
    end)
    
    local level, beli, frag = 0, 0, 0
    pcall(function()
        level = player.Data.Level.Value
        beli = player.Data.Beli.Value
        frag = player.Data.Fragments.Value
    end)
    
    local invData = GetInventoryData()
    
    local leviHeart = invData["Leviathan Heart"] or 0
    local leviScale = invData["Leviathan Scale"] or 0
    local mythicScroll = invData["Mythical Scroll"] or invData["Mythic Scroll"] or 0
    local legendScroll = invData["Legendary Scroll"] or invData["Legend Scroll"] or 0
    
    local data = {
        ["embeds"] = {{
            ["title"] = "Blox Fruits Status",
            ["description"] = "**Người chơi:** `" .. player.Name .. "`\n**ID:** `" .. player.UserId .. "`\n━━━━━━━━━━━━━━━━━━━━━━━━",
            ["color"] = 0x2b2d31,
            ["fields"] = {
                {
                    ["name"] = "HỆ THỐNG",
                    ["value"] = "> **FPS:** `" .. fps .. "`\n> **Ping:** `" .. ping .. "ms`\n> **Treo:** `" .. GetUptime() .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "NHÂN VẬT",
                    ["value"] = "> **Level:** `" .. Format(level) .. "`\n> **Beli:** `" .. Format(beli) .. "`\n> **Frag:** `" .. Format(frag) .. "`",
                    ["inline"] = true
                },
                {
                    ["name"] = "KHO ĐỒ VẬT PHẨM",
                    ["value"] = "━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                                "**Tim Levi:** `" .. leviHeart .. "`\n" ..
                                "**Vảy Levi:** `" .. leviScale .. "`\n" ..
                                "**Mythical:** `" .. mythicScroll .. "`\n" ..
                                "**Legendary:** `" .. legendScroll .. "`\n" ..
                                "━━━━━━━━━━━━━━━━━━━━━━━━",
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Cập nhật lúc: " .. os.date("%H:%M:%S") .. " | Config by " .. ConfigOwner
            }
        }}
    }

    local req = (syn and syn.request) or (http and http.request) or http_request or request
    
    local url = (MessageID and MessageID ~= "") and (WebhookURL .. "/messages/" .. MessageID) or (WebhookURL .. "?wait=true")
    local method = (MessageID and MessageID ~= "") and "PATCH" or "POST"

    if req then
        local success, res = pcall(function()
            return req({
                Url = url,
                Method = method,
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success and res and res.Success then
            if not MessageID or MessageID == "" then
                local responseData = HttpService:JSONDecode(res.Body)
                if responseData and responseData.id then
                    MessageID = responseData.id
                    if writefile then
                        writefile(FileName, tostring(MessageID))
                    end
                end
            end
        elseif success and res and not res.Success and MessageID then
            if res.StatusCode == 404 then
                MessageID = nil
                if delfile and isfile(FileName) then delfile(FileName) end
            end
        end
    end
end

task.spawn(function()
    while true do 
        Send() 
        task.wait(UpdateInterval) 
    end
end)
