local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local request = (syn and syn.request) or (http and http.request) or request

-- ✅ ใช้คอนฟิกจาก _G
local config = _G.BloxFruitsWebhookConfig or {}
if not config.webhookURL then
    warn("❌ ไม่พบ webhookURL ใน config")
    return
end
if not request then
    warn("❌ Executor ไม่รองรับ HTTP Requests")
    return
end

-- 🧠 Fighting Styles
_G.AllOwnedFightingStyles = {
    "Combat", "Black Leg", "Electro", "Water Kung Fu",
    "Dragon Breath", "Superhuman", "Death Step", "Electric Claw",
    "Sharkman Karate", "Godhuman", "Dragon Talon", "Sanguine Art"
}

-- ✅ ตรวจสอบว่าหมัดมีจริงในเกมไหม
local function verifyOwnedFightingStyles()
    local valid = {}
    local cache = game:FindFirstChild("WeaponAssetCache")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local function hasToolNamed(name)
        for _, container in ipairs({character, backpack, cache}) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == name then
                        return true
                    end
                end
            end
        end
        return false
    end

    for _, name in ipairs(_G.AllOwnedFightingStyles) do
        if hasToolNamed(name) then
            table.insert(valid, name)
        end
    end

    return #valid > 0 and table.concat(valid, ", ") or "❌ No valid fighting styles found"
end

-- 👤 ข้อมูลผู้เล่น
local function getPlayerData()
    local data = LocalPlayer:FindFirstChild("Data")
    local stats = LocalPlayer:FindFirstChild("leaderstats")

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

-- 🚀 ส่งข้อมูลไปยัง Webhook
local function sendToWebhook()
    local playerData = getPlayerData()
    local fields = {}

    local nameField = config.hideUsername and ("||`" .. playerData.name .. "`||") or ("`" .. playerData.name .. "`")
    table.insert(fields, {name = " Player Name", value = nameField, inline = true})
    if config.showBounty then table.insert(fields, {name = " Bounty / Honor", value = "`" .. playerData.bounty .. "`", inline = true}) end
    if config.showLevel then table.insert(fields, {name = " Level", value = "`" .. playerData.level .. "`", inline = true}) end
    if config.showMoney then table.insert(fields, {name = " Money", value = "`" .. playerData.money .. "`", inline = true}) end
    if config.showFragments then table.insert(fields, {name = " Fragments", value = "`" .. playerData.fragments .. "`", inline = true}) end
    if config.showRace then table.insert(fields, {name = " Race", value = "`" .. playerData.race .. "`", inline = true}) end
    if config.showFruit then table.insert(fields, {name = " Devil Fruit", value = "`" .. playerData.fruit .. "`", inline = true}) end
    if config.showFightingStyle then table.insert(fields, {name = " Melee", value = verifyOwnedFightingStyles(), inline = false}) end

    local embed = {
        title = "⚓ Blox Fruits - Player Info",
        description = "Current player status and confirmed fighting styles",
        color = 15844367,
        fields = fields,
        footer = {
            text = "📅 Updated: " .. os.date("%Y-%m-%d %X") .. "\n -# Version 4.0 | Developed by Phatt & Si"
        }
    }

    local message = {
        embeds = {embed},
        username = "Blox Fruits Bot"
    }

    local success, response = pcall(function()
        return request({
            Url = config.webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(message)
        })
    end)

    if success and response and response.Success then
        print("✅ Webhook sent successfully!")
    else
        warn("❌ Failed to send webhook!", response and response.StatusCode or "No response")
    end
end

-- 🔁 รันทันที แล้ววนซ้ำทุก 30 วินาที
sendToWebhook()
while true do wait(30) sendToWebhook() end
