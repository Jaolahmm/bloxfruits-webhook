-- Blox Fruits Webhook Script (v2.1 with Config Support)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local config = _G.BloxConfig or {}
local webhookURL = config.webhookURL or ""
local enabled = config.enable or {}

local request = (syn and syn.request) or (http and http.request) or request
if not request then warn("Executor does not support HTTP Requests") return end

local function safeGet(folder, key, fallback)
    local item = folder and folder:FindFirstChild(key)
    return item and item:IsA("ValueBase") and tostring(item.Value) or fallback
end

local function findStatByPartialName(folder, keywords)
    if not folder then return "Not Found" end
    for _, item in ipairs(folder:GetChildren()) do
        for _, keyword in ipairs(keywords) do
            if item:IsA("ValueBase") and string.find(item.Name:lower(), keyword:lower()) then
                return tostring(item.Value)
            end
        end
    end
    return "Not Found"
end

local function getPlayerData()
    local data = LocalPlayer:FindFirstChild("Data")
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    return {
        name = LocalPlayer.Name,
        bounty = findStatByPartialName(stats, {"bounty", "honor"}),
        level = safeGet(data, "Level", "Not Found"),
        money = safeGet(data, "Beli", "Not Found"),
        fragments = safeGet(data, "Fragments", "Not Found"),
        race = safeGet(data, "Race", "Not Found"),
        fruit = safeGet(data, "DevilFruit", "Not Found")
    }
end

local function sendWebhook()
    local data = getPlayerData()
    local fields = {}

    if enabled.name then table.insert(fields, {name = "Username", value = "`" .. data.name .. "`", inline = true}) end
    if enabled.bounty then table.insert(fields, {name = "Bounty / Honor", value = "`" .. data.bounty .. "`", inline = true}) end
    if enabled.level then table.insert(fields, {name = "Level", value = "`" .. data.level .. "`", inline = true}) end
    if enabled.money then table.insert(fields, {name = "Beli", value = "`" .. data.money .. "`", inline = true}) end
    if enabled.fragments then table.insert(fields, {name = "Fragments", value = "`" .. data.fragments .. "`", inline = true}) end
    if enabled.race then table.insert(fields, {name = "Race", value = "`" .. data.race .. "`", inline = true}) end
    if enabled.fruit then table.insert(fields, {name = "Devil Fruit", value = "`" .. data.fruit .. "`", inline = true}) end

    local message = {
        embeds = {{
            title = "📊 Blox Fruits - Player Info",
            color = 16753920,
            description = "Here is the latest player status:",
            fields = fields,
            footer = {text = "🕒 Updated at: " .. os.date("%Y-%m-%d %X")}
        }},
        username = "Blox Fruits Bot"
    }

    request({
        Url = webhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode(message)
    })
end

while true do
    sendWebhook()
    wait(30)
end
