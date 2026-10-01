----------- SCRIPT BUY PACK (BELI SELAMA GEMS CUKUP -> WARP STORAGE -> STOP) -----------

bot = getBot()
world = bot:getWorld()
inventory = bot:getInventory()

------- PACK SETTING -------
packname  = "world_lock"  ----- nama item di store
packID    = 242           ----- item ID hasil pembelian
pricepack = 200           ----- harga 1 pack (gems)
---------------------------

------- WORLD SETTING -------
BuyWorld       = "KOSONG KAN AJA"       ----- world tempat beli (kosongin = langsung beli di world storage)
BuyWorldID     = "SAMA AJA KOSONG AJA"       ----- door ID (kosongin kalau tidak pakai)

StorageWorld   = "WORLD BELI"  ----- world storage tujuan akhir
StorageWorldID = "BEBAS SUKA U"       ----- door ID (kosongin kalau tidak pakai)
DropPack       = "Yes"       ----- "Yes" drop semua pack di storage / "No" cuma warp
---------------------------

------- DELAY & SAFETY -------
DelayJoin   = 4     ----- detik, jeda setelah warp
DelayBuy    = 3     ----- detik, jeda setelah kirim packet beli
MaxFail     = 5     ----- stop kalau beli gagal berturut-turut sebanyak ini
---------------------------

BuyWorld       = string.upper(BuyWorld)
BuyWorldID     = string.upper(BuyWorldID)
StorageWorld   = string.upper(StorageWorld)
StorageWorldID = string.upper(StorageWorldID)

function InWorld()
    local name = tostring(world.name)
    return name ~= "" and name ~= "EXIT"
end

function Join(targetWorld, doorId)
    for try = 1, 5 do
        if doorId and doorId ~= "" then
            bot:warp(targetWorld, doorId)
        else
            bot:warp(targetWorld)
        end
        sleep(DelayJoin * 1000)
        if InWorld() and tostring(world.name):upper() == targetWorld then
            return true
        end
    end
    return false
end

function Reconnect()
    if bot.status ~= BotStatus.online then
        sleep(5000)
        while bot.status ~= BotStatus.online do
            bot:connect()
            sleep(10000)
        end
    end
    if not InWorld() then
        local w = (BuyWorld ~= "") and BuyWorld or StorageWorld
        local d = (BuyWorld ~= "") and BuyWorldID or StorageWorldID
        Join(w, d)
    end
end

function DropPacks()
    if DropPack ~= "Yes" then return end
    local tries = 0
    while inventory:getItemCount(packID) > 0 and tries < 5 do
        Reconnect()
        if tostring(world.name):upper() ~= StorageWorld then
            Join(StorageWorld, StorageWorldID)
        end
        bot:drop(packID, inventory:getItemCount(packID))
        sleep(1500)
        tries = tries + 1
    end
end

-- ===== MAIN =====
bot.auto_collect = false

if BuyWorld ~= "" then
    Join(BuyWorld, BuyWorldID)
else
    Join(StorageWorld, StorageWorldID)
end

local totalBought = 0
local failCount = 0

while bot.gem_count >= pricepack do
    Reconnect()

    local before = inventory:getItemCount(packID)
    bot:sendPacket(2, "action|buy\nitem|" .. packname)
    sleep(DelayBuy * 1000)

    if inventory:getItemCount(packID) > before then
        totalBought = totalBought + (inventory:getItemCount(packID) - before)
        failCount = 0
    else
        failCount = failCount + 1
        if failCount >= MaxFail then
            bot:say("Beli gagal " .. MaxFail .. "x berturut-turut, script dihentikan.")
            break
        end
    end
end

-- gems sudah tidak cukup (atau beli gagal) -> warp ke storage lalu stop
Reconnect()
Join(StorageWorld, StorageWorldID)
DropPacks()
bot:say("Selesai. Total dibeli: " .. totalBought .. " | Sisa gems: " .. bot.gem_count)
sleep(1000)
bot:leaveWorld()
return
