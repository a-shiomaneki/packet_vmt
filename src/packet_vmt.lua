-- packet-vmt.lua
-- A Wireshark Plugin for 'Virtual Motion Tracker' packet dissection
--
-- Copyright (c) 2021, A.Shiomaneki <a.shiomaneki@gmail.com>
--
-- This program is released under the MIT License.
-- http://opensource.org/licenses/mit-license.php


proto = Proto('vmt', 'Virtual Motion Tracker Protocol')

vmt_size_F = ProtoField.new('Size', 'vmt.size', ftypes.UINT32)
vmt_path_F = ProtoField.new('Path', 'vmt.path', ftypes.STRING)
vmt_format_F = ProtoField.new('Format', 'vmt.format', ftypes.STRING)
vmt_valid_format_F = ProtoField.new('Valid Format', 'vmt.valid_format', ftypes.BOOLEAN)
vmt_index_F = ProtoField.new('Index', 'vmt.index', ftypes.INT32)
vmt_enable_F = ProtoField.new('Enable', 'vmt.enable', ftypes.UINT32)
vmt_timeoffset_F = ProtoField.new('Time Offset', 'vmt.timeoffset', ftypes.FLOAT)
vmt_x_F = ProtoField.new('x', 'vmt.x', ftypes.FLOAT)
vmt_y_F = ProtoField.new('y', 'vmt.y', ftypes.FLOAT)
vmt_z_F = ProtoField.new('z', 'vmt.z', ftypes.FLOAT)
vmt_qx_F = ProtoField.new('qx', 'vmt.qx', ftypes.FLOAT)
vmt_qy_F = ProtoField.new('qy', 'vmt.qy', ftypes.FLOAT)
vmt_qz_F = ProtoField.new('qz', 'vmt.qz', ftypes.FLOAT)
vmt_qw_F = ProtoField.new('qw', 'vmt.qw', ftypes.FLOAT)
vmt_serial_F = ProtoField.new('Serial', 'vmt.serial', ftypes.STRING)
vmt_buttonindex_F = ProtoField.new('Button Index', 'vmt.button_index', ftypes.INT32)
vmt_button_value_F = ProtoField.new('Button Value', 'vmt.button_value', ftypes.INT32)
vmt_triggerindex_F = ProtoField.new('Trigger Index', 'vmt.trigger_index', ftypes.INT32)
vmt_trigger_value_F = ProtoField.new('Trigger Value', 'vmt.trigger_value', ftypes.FLOAT)
vmt_joystickindex_F = ProtoField.new('Joystick Index', 'vmt.joystick_index', ftypes.INT32)
vmt_joystic_x_F = ProtoField.new('Joystic x', 'vmt.joystic_x', ftypes.FLOAT)
vmt_joystic_y_F = ProtoField.new('Joystic y', 'vmt.joystic_y', ftypes.FLOAT)
vmt_stat_F = ProtoField.new('Stat', 'vmt.stat', ftypes.INT32)
vmt_msg_F = ProtoField.new('Msg', 'vmt.msg', ftypes.STRING)
vmt_version_F = ProtoField.new('Version', 'vmt.version', ftypes.STRING)
vmt_installpath_F = ProtoField.new('Install Path', 'vmt.installpath', ftypes.STRING)
vmt_frequency_F = ProtoField.new('Frequency', 'vmt.frequency', ftypes.FLOAT)
vmt_amplitude_F = ProtoField.new('Amplitude', 'vmt.amplitude', ftypes.FLOAT)
vmt_duration_F = ProtoField.new('Duration', 'vmt.duration', ftypes.FLOAT)
vmt_room_matrix_F = ProtoField.new('Room Matrix', 'vmt.room_matrix', ftypes.NONE)

vmt_matrix_val_Fs = {}
for i = 1, 12 do
    local name = 'm' .. tostring(i)
    vmt_matrix_val_Fs[i] = ProtoField.new(name, 'vmt.room_matrix.' .. name , ftypes.FLOAT)
end

proto.fields = {
    vmt_size_F, vmt_path_F, vmt_format_F, vmt_valid_format_F,
    vmt_index_F, vmt_enable_F, vmt_timeoffset_F,
    vmt_x_F, vmt_y_F, vmt_z_F,
    vmt_qx_F, vmt_qy_F, vmt_qz_F, vmt_qw_F,
    vmt_serial_F,
    vmt_buttonindex_F, vmt_button_value_F,
    vmt_triggerindex_F, vmt_trigger_value_F, 
    vmt_joystickindex_F, vmt_joystic_x_F, mt_joystic_y_F,
    vmt_stat_F, vmt_msg_F,
    vmt_version_F, vmt_installpath_F,
    vmt_frequency_F, vmt_amplitude_F, vmt_duration_F,
    vmt_room_matrix_F
}
for i = 1, #vmt_matrix_val_Fs do
    proto.fields[#proto.fields + 1] = vmt_matrix_val_Fs[i]
end

-- Open Sound Control (OSC) argument types enumeration
osc_type = {
    INT32   = 'i',
    FLOAT   = 'f',
    STRING  = 's',
    BLOB    = 'b',

    TRUE    = 'T',
    FALSE   = 'F',
    NIL     = 'N',
    BANG    = 'I',

    INT64   = 'h',
    DOUBLE  = 'd',
    TIMETAG = 't',

    SYMBOL  = 'S',
    CHAR    = 'c',
    RGBA    = 'r',
    MIDI    = 'm'
}
-- characters not allowed in OSC path string
invalid_path_chars = {' ', '#', '\0'}

-- allowed characters in OSC format string
valid_format_chars = {
    osc_type.INT32,   osc_type.FLOAT,  
    osc_type.STRING,  osc_type.BLOB,
    osc_type.TRUE,    osc_type.FALSE,
    osc_type.NIL,     osc_type.BANG,
    osc_type.INT64,   osc_type.DOUBLE,
    osc_type.TIMETAG, osc_type.SYMBOL,
    osc_type.CHAR,    osc_type.RGBA,
    osc_type.MIDI,
    '\0'
}

-- sub path string
sub_path = {
    ROOM                = '/Room',
    RAW                 = '/Raw', 
    JOINT               = '/Joint', 
    FOLLOW              = '/Follow', 
    INPUT_BUTTON        = '/Input/Button',
    INPUT_TRIGGER       = '/Input/Trigger',
    INPUT_JOYSTICK      = '/Input/Joystick',
    RESET               = '/Reset',
    LOADSETTING         = '/LoadSetting',
    SETROOMMATRIX       = '/SetRoomMatrix',
    SETAUTOPOSEUPDATE   = '/SetAutoPoseUpdate',
    OUT_LOG             = '/Out/Log',
    OUT_ALIVE           = '/Out/Alive',
    OUT_HAPTIC          = '/Out/Haptic'       
}

-- allowed format string for VMT
valid_format_string = {
    [sub_path.ROOM]                 = ',iiffffffff',
    [sub_path.RAW]                  = ',iiffffffff', 
    [sub_path.JOINT]                = ',iiffffffffs', 
    [sub_path.FOLLOW]               = ',iiffffffffs', 
    [sub_path.INPUT_BUTTON]         = ',iifi', 
    [sub_path.INPUT_TRIGGER]        = ',iiff',
    [sub_path.INPUT_JOYSTICK]       = ',iifff',
    [sub_path.RESET]                = ',',
    [sub_path.LOADSETTING]          = ',',
    [sub_path.SETROOMMATRIX]        = ',ffffffffffff',
    [sub_path.SETAUTOPOSEUPDATE]    = ',i',
    [sub_path.OUT_LOG]              = ',is',
    [sub_path.OUT_ALIVE]            = ',ss',
    [sub_path.OUT_HAPTIC]           = ',ifff'
}

local function string_length_mult4(str)
    return  (#str + 1) + (4 - (#str + 1))%4
end

local function heuristic_checker(buffer, pinfo, tree)
    -- guard for length
    if buffer:len() < 3 then return false end

    local path = buffer():stringz()
    -- if string.sub(path, 1, 1) ~= '/' then return false end
    if string.sub(path, 1, 4) ~= '/VMT' then return false end
    for i = 2, #path do
        for j = 1, #invalid_path_chars do
            if string.sub(path, i, i) == invalid_path_chars[j] then 
                return false 
            end
        end
    end

    -- local len_of_path_with_null_and_padding = (#path + 1) + 4 - (#path + 1)%4
    local format = buffer(string_length_mult4(path)):stringz()
    if string.sub(format, 1, 1) ~= ',' then return false end
    for i = 2, #format do
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
    pinfo.cols.protocol = 'VMT'

    local subtree = tree:add(proto, buffer())
    -- local message = buffer():string()
    -- local path = string.match(message, '([%w/]+)')
    local path = buffer():stringz()
    -- local format = string.match(message, '([%w]+)', path:len() + 2)
    local format = buffer(string_length_mult4(path)):stringz()
    local is_valid_format = false

    subtree:add(vmt_path_F, path)
    subtree:add(vmt_format_F, format)
    local info = string.format('%s ', path)

    local cursor = string_length_mult4(path) + string_length_mult4(format)

    local is_control_vmt = false
    for i, val in pairs{sub_path.ROOM, sub_path.RAW, sub_path.JOINT, sub_path.FOLLOW} do
        if path:find(val) == 5 then
            is_control_vmt = true
            is_valid_format = valid_format_string[val] == format
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
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_index_F, index)
        subtree:add(vmt_enable_F, enable)
        subtree:add(vmt_timeoffset_F, timeoffset)
        subtree:add(vmt_x_F, x)
        subtree:add(vmt_y_F, y)
        subtree:add(vmt_z_F, z)
        subtree:add(vmt_qx_F, qx)
        subtree:add(vmt_qy_F, qy)
        subtree:add(vmt_qz_F, qz)
        subtree:add(vmt_qw_F, qw)
        info = info .. string.format('%d,%d,%4.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f',index,enable,timeoffset,x,y,z,qx,qy,qz,qw)
    end

    local has_serial = false
    for i, val in pairs{sub_path.JOINT, sub_path.FOLLOW} do
        if path:find(val) == 5 then
            has_serial = true
            break
        end
    end
    if has_serial then
        local serial = buffer(cursor + 40, -1):stringz()
        subtree:add(vmt_serial_F, serial)
        info = info .. string.format('%s', serial)
    end

    if path:find(sub_path.INPUT_BUTTON) == 5 then
        is_valid_format = valid_format_string[sub_path.INPUT_BUTTON] == format
        local index = buffer(cursor, 4):int()
        local buttonindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):float()
        local button_value = buffer(cursor + 12, 4):int()
        subtree:add(vmt_valid_format_F, is_valid_format)      
        subtree:add(vmt_index_F, index)
        subtree:add(vmt_buttonindex_F, buttonindex)
        subtree:add(vmt_timeoffset_F, timeoffset)
        subtree:add(vmt_button_value_F, button_value)
        info = info .. string.format('%d,%d,%4.2f,%d', index, buttonindex, timeoffset, button_value)
    end
    if path:find(sub_path.INPUT_TRIGGER) == 5 then
        is_valid_format = valid_format_string[sub_path.INPUT_TRIGGER] == format
        local index = buffer(cursor, 4):int()
        local triggerindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):float()
        local trigger_value = buffer(cursor + 12, 4):float()
        subtree:add(vmt_valid_format_F, is_valid_format) 
        subtree:add(vmt_index_F, index)
        subtree:add(vmt_triggerindex_F, triggerindex)
        subtree:add(vmt_timeoffset_F, timeoffset)
        subtree:add(vmt_trigger_value_F, trigger_value)
        info = info .. string.format('%d,%d,%4.2f,%4.1f', index, triggerindex, timeoffset, trigger_value)
    end
    if path:find(sub_path.INPUT_JOYSTICK) == 5 then
        is_valid_format = valid_format_string[sub_path.INPUT_JOYSTICK] == format
        local index = buffer(cursor, 4):int()
        local joystickindex = buffer(cursor + 4, 4):int()
        local timeoffset = buffer(cursor + 8, 4):float()
        local joystic_x = buffer(cursor + 12, 4):float()
        local joystic_y = buffer(cursor + 16, 4):float()
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_index_F, index)
        subtree:add(vmt_joystickindex_F, joystickindex)
        subtree:add(vmt_timeoffset_F, timeoffset)
        subtree:add(vmt_joystic_x_F, joystic_x)
        subtree:add(vmt_joystic_y_F, joystic_y)
        info = info .. string.format('%d,%d,%4.2f,%4.1f,%4.1f', index, joystickindex, timeoffset, joystic_x, joystic_y)
    end

    if path:find(sub_path.RESET) == 5 then
        is_valid_format = valid_format_string[sub_path.RESET] == format
        subtree:add(vmt_valid_format_F, is_valid_format)
    end

    if path:find(sub_path.LOADSETTING) == 5 then
        is_valid_format = valid_format_string[sub_path.LOADSETTING] == format
        subtree:add(vmt_valid_format_F, is_valid_format)
    end

    if path:find(sub_path.SETROOMMATRIX) == 5 then
        is_valid_format = valid_format_string[sub_path.SETROOMMATRIX] == format
        subtree:add(vmt_valid_format_F, is_valid_format)
        local room_matrix_tree = subtree:add(vmt_room_matrix_F)
        for i = 1, #vmt_matrix_val_Fs do
            local val = buffer(cursor + (i - 1)*4, 4):float()
            room_matrix_tree:add(vmt_matrix_val_Fs[i], val)
            info = info .. string.format('%5.2f', val)
            if i < #vmt_matrix_val_Fs then
                info = info .. ','
            end
        end
    end

    if path:find(sub_path.SETAUTOPOSEUPDATE) == 5 then
        is_valid_format = valid_format_string[sub_path.SETAUTOPOSEUPDATE] == format
        local enable = buffer(cursor, 4):int()
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_enable_F, enable)
        info = info .. string.format('%d', enable)
    end

    if path:find(sub_path.OUT_LOG) == 5 then
        is_valid_format = valid_format_string[sub_path.OUT_LOG] == format
        local stat = buffer(cursor, 4):int()
        local msg = buffer(cursor + 4, -1):string()
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_stat_F, stat)
        subtree:add(vmt_msg_F, msg)
        info = info .. string.format('%d,%s', stat, msg)
    end

    if path:find(sub_path.OUT_ALIVE) == 5 then
        is_valid_format = valid_format_string[sub_path.OUT_ALIVE] == format
        local version = buffer(cursor):stringz()
        local installpath = buffer(cursor + string_length_mult4(version), -1):stringz()
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_version_F, version)
        subtree:add(vmt_installpath_F, installpath)
        info = info .. string.format('%s,%s', version, installpath)
    end

    if path:find(sub_path.OUT_HAPTIC) == 5 then
        is_valid_format = valid_format_string[sub_path.OUT_HAPTIC] == format
        local index = buffer(cursor, 4):int()
        local frequency = buffer(cursor + 4, 4):float()
        local amplitude = buffer(cursor + 8, 4):float()
        local duration = buffer(cursor + 12, 4):float()
        subtree:add(vmt_valid_format_F, is_valid_format)
        subtree:add(vmt_index_F, index)
        subtree:add(vmt_frequency_F, frequency)
        subtree:add(vmt_amplitude_F, amplitude)
        subtree:add(vmt_duration_F, duration)
        info = info .. string.format('%d,%f,%f,%f', index, frequency, amplitude, duration)
    end

    pinfo.cols.info = info
end

proto:register_heuristic('udp', heuristic_checker)

