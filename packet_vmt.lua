-- packet-vmt.lua
-- A Wireshark Plugin for "Virtual Motion Tracker" packet dissection
--
-- Copyright (c) 2021, A.Shiomaneki <a.shiomaneki@gmail.com>
--
-- This program is released under the MIT License.
-- http://opensource.org/licenses/mit-license.php


proto = Proto("vmt", "VirtualMotionTracker Protocol")

vmt_size_F = ProtoField.new("size", "vmt.size", ftypes.UINT32)
vmt_path_F = ProtoField.new("path", "vmt.path", ftypes.STRING)
vmt_format_F = ProtoField.new("format", "vmt.format", ftypes.STRING)
vmt_index_F = ProtoField.new("index", "vmt.index", ftypes.INT32)
vmt_enable_F = ProtoField.new("enable", "vmt.enable", ftypes.UINT32)
vmt_timeoffset_F = ProtoField.new("timeoffset", "vmt.timeoffset", ftypes.FLOAT)
vmt_x_F = ProtoField.new("x", "vmt.x", ftypes.FLOAT)
vmt_y_F = ProtoField.new("y", "vmt.y", ftypes.FLOAT)
vmt_z_F = ProtoField.new("z", "vmt.z", ftypes.FLOAT)
vmt_qx_F = ProtoField.new("qx", "vmt.qx", ftypes.FLOAT)
vmt_qy_F = ProtoField.new("qy", "vmt.qy", ftypes.FLOAT)
vmt_qz_F = ProtoField.new("qz", "vmt.qz", ftypes.FLOAT)
vmt_qw_F = ProtoField.new("qw", "vmt.qw", ftypes.FLOAT)
vmt_serial_F = ProtoField.new("serial", "vmt.serial", ftypes.INT32)
vmt_value_F = ProtoField.new("value", "vmt.value", ftypes.INT32)
vmt_buttonindex_F = ProtoField.new("buttonindex", "vmt.buttonindex", ftypes.INT32)
vmt_joystickindex_F = ProtoField.new("joystickindex", "vmt.joystickindex", ftypes.INT32)

proto.fields = {
    vmt_size_F, vmt_path_F, vmt_format_F,
    vmt_index_F, vmt_enable_F, vmt_timeoffset_F,
    vmt_x_F, vmt_y_F, vmt_z_F,
    vmt_qx_F, vmt_qy_F, vmt_qz_F, vmt_qw_F,
    vmt_serial_F
}

-- Open Sound Control (OSC) argument types enumeration
osc_type = {
    OSC_INT32   = 'i',
    OSC_FLOAT   = 'f',
    OSC_STRING  = 's',
    OSC_BLOB    = 'b',

    OSC_TRUE    = 'T',
    OSC_FALSE   = 'F',
    OSC_NIL     = 'N',
    OSC_BANG    = 'I',

    OSC_INT64   = 'h',
    OSC_DOUBLE  = 'd',
    OSC_TIMETAG = 't',

    OSC_SYMBOL  = 'S',
    OSC_CHAR    = 'c',
    OSC_RGBA    = 'r',
    OSC_MIDI    = 'm'
}
-- characters not allowed in OSC path string
invalid_path_chars = {' ', '#', '\0'}

-- allowed characters in OSC format string
valid_format_chars = {
    osc_type.OSC_INT32,   osc_type.OSC_FLOAT,  
    osc_type.OSC_STRING,  osc_type.OSC_BLOB,
    osc_type.OSC_TRUE,    osc_type.OSC_FALSE,
    osc_type.OSC_NIL,     osc_type.OSC_BANG,
    osc_type.OSC_INT64,   osc_type.OSC_DOUBLE,
    osc_type.OSC_TIMETAG, osc_type.OSC_SYMBOL,
    osc_type.OSC_CHAR,    osc_type.OSC_RGBA,
    osc_type.OSC_MIDI,
    '\0'
}

local function heuristic_checker(buffer, pinfo, tree)
    -- guard for length
    if buffer:len() < 3 then return false end

    local path = buffer():stringz()
    -- if string.sub(path, 1, 1) ~= '/' then return false end
    if string.sub(path, 1, 4) ~= '/VMT' then return false end
    for i = 2, path:len()-1 do
        for j = 1, #invalid_path_chars do
            if string.sub(path, i, i) == invalid_path_chars[j] then 
                return false 
            end
        end
    end

    local format = buffer(path:len()+1):stringz()
    if string.sub(format, 1, 1) ~= ',' then return false end
    for i = 2, format:len()-1 do
        local isValied = false
        for j = 1, #valid_format_chars do
            if string.sub(format, i, i) == valid_format_chars[j] then
                isValied = true
                break
            end
        end
        if not isValied then return false end
    end

    proto.dissector(buffer, pinfo, tree)
    return true
end

function proto.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = "VMT"

    local subtree = tree:add(proto, buffer())
    local message = buffer():string()
    -- local path = string.match(message, "([%w/]+)")
    local path = buffer():stringz()
    -- local format = string.match(message, "([%w]+)", path:len() + 2)
    local format = buffer(path:len()+1):stringz()

    subtree:add(vmt_path_F, path)
    subtree:add(vmt_format_F, format)
    local cursor = path:len() + format:len() + 2
    local info = string.format("%s", path)

    local is_control_vmt = false
    for i, val in pairs{"/Room", "/Raw", "/Joint", "/Fllow", "/Joint", "/Fllow"} do
        if path:find(val) == 5 then
            is_control_vmt = true
            break
        end
    end
    if is_control_vmt then
        local index = buffer(cursor, 4):int()
        local enable = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):float()
        local x = buffer(cursor + 12, 4):float()
        local y = buffer(cursor + 16, 4):float()
        local z = buffer(cursor + 20, 4):float()
        local qx = buffer(cursor + 24, 4):float()
        local qy = buffer(cursor + 28, 4):float()
        local qz = buffer(cursor + 32, 4):float()
        local qw = buffer(cursor + 36, 4):float()
        subtree:add(vmt_index_F, buffer(cursor, 4):int())
        subtree:add(vmt_enable_F, buffer(cursor + 4, 4):int())
        subtree:add(vmt_timeoffset_F, buffer(cursor + 8, 4):float())
        subtree:add(vmt_x_F, buffer(cursor + 12, 4):float())
        subtree:add(vmt_y_F, buffer(cursor + 16, 4):float())
        subtree:add(vmt_z_F, buffer(cursor + 20, 4):float())
        subtree:add(vmt_qx_F, buffer(cursor + 24, 4):float())
        subtree:add(vmt_qy_F, buffer(cursor + 28, 4):float())
        subtree:add(vmt_qz_F, buffer(cursor + 32, 4):float())
        subtree:add(vmt_qw_F, buffer(cursor + 36, 4):float())
        info = info .. string.format("%d,%d,%4.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f",index,enable,timeoffset,x,y,z,qx,qy,qz,qw)
    end

    local has_serial = false
    for i, val in pairs{"/Joint", "/Fllow"} do
        if path:find(val) == 5 then
            has_serial = true
            break
        end
    end
    if has_serial then
        local serial = buffer(cursor + 40, -1):string()
        subtree:add(vmt_serial_F, buffer(cursor + 40, -1))
        info = info .. string.format("%s", serial)
    end

    if path:find("/Input/Button") == 5 then
        local index = buffer(cursor, 4):int()
        local buttonindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):int()
        local value = buffer(cursor + 12, 4):int()
        subtree:add(vmt_index_F, buffer(cursor, 4):int())
        subtree:add(vmt_buttonindex_F, buffer(cursor + 4, 4):int())
        subtree:add(vmt_timeoffset_F, buffer(cursor + 8, 4):float())
        subtree:add(vmt_value_F, buffer(cursor + 12, 4):float())
        info = info .. string.format("%d,%d,%d,%d", index, buttonindex, timeoffset, value)
    end
    if path:find("/Input/Trigger") == 5 then
        local index = buffer(cursor, 4):int()
        local triggerindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):int()
        local value = buffer(cursor + 12, 4):int()
        subtree:add(vmt_index_F, buffer(cursor, 4):int())
        subtree:add(vmt_triggerindex_F, buffer(cursor + 4, 4):int())
        subtree:add(vmt_timeoffset_F, buffer(cursor + 8, 4):float())
        subtree:add(vmt_value_F, buffer(cursor + 12, 4):float())
        info = info .. string.format("%d,%d,%d,%d", index, triggerindex, timeoffset, value)
    end
    if path:find( "/Input/Joystick") == 5 then
        local index = buffer(cursor, 4):int()
        local joystickindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):int()
        local value = buffer(cursor + 12, 4):int()
        subtree:add(vmt_index_F, buffer(cursor, 4):int())
        subtree:add(vmt_joystickindex_F, buffer(cursor + 4, 4):int())
        subtree:add(vmt_timeoffset_F, buffer(cursor + 8, 4):float())
        subtree:add(vmt_jx_F, buffer(cursor + 12, 4):float())
        subtree:add(vmt_jy_F, buffer(cursor + 16, 4):float())
        info = info .. string.format("%d,%d,%d,%d", index, joystickindex, timeoffset, value)
    end

    pinfo.cols.info = info
end

proto:register_heuristic("udp", heuristic_checker)

-- References
-- VMT - Virtual Motion Tracker
-- https://github.com/gpsnmeajp/VirtualMotionTracker
-- Creating port-independent (heuristic) Wireshark dissectors in Lua
-- https://mika-s.github.io/wireshark/lua/dissector/2018/12/30/creating-port-independent-wireshark-dissectors-in-lua.html
-- packet-osc.c
-- https://gitlab.com/wireshark/wireshark/-/blob/master/epan/dissectors/packet-osc.c
