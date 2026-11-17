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

local function GetInventoryData()
    local inventory = {}
    pcall(function()
        local inv = CommF:InvokeServer("getInventory")
        for _, v in pairs(inv or {}) do 
            inventory[v.Name] = v.Count
        end
    end)
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
        ping = math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
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
    local mythicScroll = invData["Mythical Scroll"] or 0
    local legendScroll = invData["Legendary Scroll"] or 0
    
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
