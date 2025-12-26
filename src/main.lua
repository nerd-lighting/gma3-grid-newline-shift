-- TODO make pop-up for no fixtures selected

local pluginName    = select(1,...);
local componentName = select(2,...); 
local signalTable   = select(3,...);
local my_handle     = select(4,...);

local debug = false

function main()
    -- enable debugging with VSCode
    if debug then
        require 'gma3_debug'()
        debuggee.print("log", "start")
    end

    -- create undo point
    local undo = CreateUndo(pluginName)

    -- Store the return in a local variable
    local fixtureIndex, gridX, gridY, gridZ = SelectionFirst()

    -- Store the subfixture handle and start the fixtures table
    local fixture_handle = GetSubfixture(fixtureIndex)
    local grid_rows = {}

    -- Cancel the plugin if no fixture is selected
    assert(fixtureIndex,"Please select a (range of) fixture(s) and try again.")
    
    -- Loop to retrieve subfixture index, fid, and grid positions
    while fixtureIndex do
        Printf('The fixture has index number: %i and gridposition %i / %i / %i',
            fixtureIndex, gridX, gridY, gridZ);

        -- create table row if doesn't exist
        if grid_rows[gridY] == nil then
            grid_rows[gridY] = {}
        end
        
        -- append the subfixture to the row list
        table.insert(grid_rows[gridY], {
            handle  = fixture_handle,
            fid     = fixture_handle:ToAddr(),
            gridX   = gridX,
            gridY   = gridY,
            gridZ   = gridZ
        })
        
        -- Get next fixture, loop will break with nil at end
        fixtureIndex, gridX, gridY, gridZ = SelectionNext(fixtureIndex)
        fixture_handle = GetSubfixture(fixtureIndex)
    end

    -- Got all subfixtures, clear the selection (just one clear to save values in programmer)
    Cmd("Clear", undo)

    Printf(dump_table(grid_rows))

    -- Sort the keys so that rows are done in order lowest --> greatest
    -- make a list with the row keys
    local rows = {}
    for k in pairs(grid_rows) do
        table.insert(rows, k)
    end

    -- sort the list
    table.sort(rows)

    -- execute the new selection with the sorted row keys
    local x_offset = 0
    local next_x_offset = 0
    for _, row in ipairs(rows) do
        Printf(row)
        -- Loop (item)
        for i in pairs(grid_rows[row]) do
            local subfixture = grid_rows[row][i]
            local new_x = subfixture["gridX"] + x_offset
            -- Set grid xyz to subfixture x + x_offset, current row, old subfixture z
            Cmd("Grid " .. new_x .. "/" .. row .. "/" .. subfixture["gridZ"], undo)
            
            -- Select the fixture
            Cmd(subfixture["fid"], undo)

            -- if new_x > next_x_offset, next_x_offset = new_x
            -- shift the next_x_offset for the next row
            if new_x > next_x_offset then
                next_x_offset = new_x
            end
        end
        
        -- update x_offset for next row
        x_offset = next_x_offset + 1
    end

    -- Close the undo
    CloseUndo(undo)

    -- end debug
    if debug then
        debuggee.print("log", "done")
    end
end

return main