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
local WebhookURL = "https://discord.com/api/webhooks/1571577249969209355/PfcUMz8o7mtqqWA58J9E8vBnTCRmE9EkXuGFvFnqB7l9zbqyXz5E656MYp3jTel9v5vB"
local UpdateInterval = 30
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

local rawDebugString = "Đang chờ dữ liệu..."

-- Thu thập đa cấu trúc + Lưu mẫu Debug
local function GetInventoryData()
    local inventory = {}
    local success, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    
    if success and type(inv) == "table" then
        rawDebugString = ""
        local debugCount = 0
        
        for k, v in pairs(inv) do 
            local name = ""
            local count = 1
            
            -- Hỗ trợ mọi loại cấu trúc table mà Blox Fruits có thể đổi
            if type(v) == "table" then
                name = tostring(v.Name or v.name or v.ItemName or k)
                count = tonumber(v.Count or v.count or v.Value or v.Amount) or 1
            elseif type(k) == "string" then
                name = k
                count = tonumber(v) or 1
            end
            
            if name ~= "" and name ~= "nil" then
                inventory[name] = count
                -- Lưu 5 item đầu tiên để gửi lên Discord xem cấu trúc
                if debugCount < 5 then
                    rawDebugString = rawDebugString .. name .. ":" .. count .. ", "
                    debugCount = debugCount + 1
                end
            end
        end
        if rawDebugString == "" then rawDebugString = "Túi đồ rỗng hoặc Cấu trúc bị mã hoá" end
    else
        rawDebugString = "Lỗi gọi getInventory (Remote có thể đã đổi)"
    end
    return inventory
end

-- Tìm kiếm mờ (Không phân biệt hoa/thường, không ngại khoảng trắng)
local function GetCount(invData, keyword)
    keyword = string.lower(keyword)
    local total = 0
    for name, count in pairs(invData) do
        if string.find(string.lower(name), keyword, 1, true) then
            total = total + count
        end
    end
    return total
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
    
    -- Áp dụng tìm kiếm mờ
    local leviHeart = GetCount(invData, "leviathan heart")
    local leviScale = GetCount(invData, "leviathan scale")
    local mythicScroll = GetCount(invData, "mythical scroll") + GetCount(invData, "mythic scroll")
    local legendScroll = GetCount(invData, "legendary scroll") + GetCount(invData, "legend scroll")
    
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
                                "━━━━━━━━━━━━━━━━━━━━━━━━\n**[DEBUG RAW DATA TÚI ĐỒ]**\n`" .. rawDebugString .. "`",
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
