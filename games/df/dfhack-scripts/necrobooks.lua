-----
-- Search for and/or get rid of necromantic books

local function do_book_stuff(item, args)
    -- Do things to books. Returns number found, actions taken (integers)
    local action_count = 0
    local found_count = 0
    local desc = dfhack.items.getDescription(item, 0, 1)

    for i, improvement in ipairs (item.improvements) do
        if improvement._type == df.itemimprovement_pagesst or improvement._type == df.itemimprovement_writingst then
            for _, content_id in ipairs (improvement.contents) do
                local content = df.written_content.find(content_id)
                for _, ref in ipairs(content.refs) do
                    if ref._type == df.general_ref_interactionst then
                        local forbid = (item.flags.forbid and " (forbidden)" or "")
                        local dump = (item.flags.dump and " (marked for dumping)" or "")
			found_count = found_count + 1
                        print("** Necrobook  found! "..desc..forbid..dump)

                        if args.dump and not item.flags.dump then
                            item.flags.dump = 1
                            print("  Marked for dumping.")
                            action_count = action_count + 1
                        end
                        if args.forbid and not item.flags.forbid then
                            item.flags.forbid = 1
                            print("  Forbidden.")
                            action_count = action_count + 1
                        elseif args.claim and item.flags.forbid then
                            item.flags.forbid = 0
                            print("  Claimed.")
                            action_count = action_count + 1
                        end

                    end
                end
            end
        end
    end

    return {found_count=found_count, action_count=action_count}
end

-- Main
argparse = require('argparse')
utils = require('utils')

local args = argparse.processArgs({...}, utils.invert{'dump', 'forbid', 'claim'})
local action_count = 0
local found_count = 0
for _,item in ipairs(df.global.world.items.other.BOOK) do
    counts = do_book_stuff(item, args)
    found_count = found_count + counts.found_count
    action_count = action_count + counts.action_count
end


for _,item in ipairs(df.global.world.items.other.TOOL) do
    counts = do_book_stuff(item, args)
    found_count = found_count + counts.found_count
    action_count = action_count + counts.action_count
end

if action_count > 0 then
    print("Total found: "..found_count.."; Total actions: "..action_count)
elseif found_count > 0 then
    print("Total found: "..found_count.."; No actions were taken.")
else
    print("No necrobooks found!")
end

