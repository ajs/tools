-----
-- Find any unattended items that have flags that prevent being picked up
-- OTHER THAN explicitly being forbidden and make them accessible.

local item_count = 0
for _,item in ipairs(df.global.world.items.all) do
    if item.flags.on_ground and not item.flags.forbid then
        local name = dfhack.items.getDescription(item, item:getType())
        local item_is = 0
        if item.flags.trader then
            print("Trader item: "..name)
            item_count = item_count + 1
            item.flags.trader = false
        else if item.flags.hostile then
            print("Hostile owned item: "..name)
            item_count = item_count + 1
            item.flags.hostile = false
        else if item.flags.hidden then
            print("Hidden item: "..name)
            item_count = item_count + 1
            item.flags.hidden = false
        else if item.flags.removed then
            print("Removed item: "..name)
            item_count = item_count + 1
            item.flags.removed = false
        end end end end
    end
end

if item_count > 0 then
    print("Total reclaimed items: "..item_count)
end
