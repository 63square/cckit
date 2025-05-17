local HIDDEN_PATH = "/hidden/" -- for testing

_G = _G._G

-- Read MOTD status
local motd_disabled = false
local settings_file, _ = fs.open(HIDDEN_PATH .. ".settings", "r")
if settings_file then
    local settings_data = textutils.unserialize(settings_file.readAll())
    settings_file.close()

    motd_disabled = settings_data["motd.enable"] == false
end

-- Old functions
local old_shell_resolve = shell.resolve
local old_fs_list = _G.fs.list
local old_fs_getSize = _G.fs.getSize
local old_fs_exists = _G.fs.exists
local old_fs_isDir = _G.fs.isDir
local old_fs_isReadOnly = _G.fs.isReadOnly
local old_fs_makeDir = _G.fs.makeDir
local old_fs_move = _G.fs.move
local old_fs_copy = _G.fs.copy
local old_fs_delete = _G.fs.delete
local old_fs_open = _G.fs.open
local old_fs_getDrive = _G.fs.getDrive
local old_fs_getFreeSpace = _G.fs.getFreeSpace
local old_fs_getCapacity = _G.fs.getCapacity
local old_fs_attributes = _G.fs.attributes
local old_ipairs = _G.ipairs

-- Patch file handles, not perfect
local protected = { "/.settings", "/motd.lua", HIDDEN_PATH }

local function simpleFSSpoofFunc(old_fn)
    return function(path, ...)
        local file_path = old_shell_resolve(path)

        for _, protected_path in old_ipairs(protected) do
            if old_shell_resolve(protected_path) == file_path then
                return old_fn(HIDDEN_PATH .. protected_path, ...)
            end
        end

        return old_fn(path, ...)
    end
end

_G.fs.list = function(path)
    local file_path = old_shell_resolve(path)
    for _, protected_path in old_ipairs(protected) do
        if old_shell_resolve(protected_path) == file_path then
            return old_fs_list(HIDDEN_PATH .. protected_path)
        end
    end

    local output = old_fs_list(path)
    local new_output = {}

    for _, item in old_ipairs(output) do
        local item_path = old_shell_resolve(file_path .. "/" .. item)
        for _, protected_path in old_ipairs(protected) do
            if old_shell_resolve(protected_path) == item_path then
                goto continue
            end
        end
        table.insert(new_output, item)
        ::continue::
    end

    return new_output
end

_G.fs.getSize = simpleFSSpoofFunc(old_fs_getSize)
_G.fs.exists = simpleFSSpoofFunc(old_fs_exists)
_G.fs.isDir = simpleFSSpoofFunc(old_fs_isDir)
_G.fs.isReadOnly = simpleFSSpoofFunc(old_fs_isReadOnly)
_G.fs.makeDir = simpleFSSpoofFunc(old_fs_makeDir)

_G.fs.move = function(path, dest)
    path = old_shell_resolve(path)
    dest = old_shell_resolve(dest)
    for _, protected_path in old_ipairs(protected) do
        if old_shell_resolve(protected_path) == path then
            path = HIDDEN_PATH .. protected_path
            break
        end
        if old_shell_resolve(protected_path) == dest then
            dest = HIDDEN_PATH .. protected_path
            break
        end
    end
    return old_fs_move(path, dest)
end
_G.fs.copy = function(path, dest)
    path = old_shell_resolve(path)
    dest = old_shell_resolve(dest)
    for _, protected_path in old_ipairs(protected) do
        if old_shell_resolve(protected_path) == path then
            path = HIDDEN_PATH .. protected_path
            break
        end
        if old_shell_resolve(protected_path) == dest then
            dest = HIDDEN_PATH .. protected_path
            break
        end
    end
    return old_fs_copy(path, dest)
end

_G.fs.delete = simpleFSSpoofFunc(old_fs_delete)
_G.fs.open = simpleFSSpoofFunc(old_fs_open)
_G.fs.getDrive = simpleFSSpoofFunc(old_fs_getDrive)
_G.fs.getFreeSpace = simpleFSSpoofFunc(old_fs_getFreeSpace)
_G.fs.getCapacity = simpleFSSpoofFunc(old_fs_getCapacity)
_G.fs.attributes = simpleFSSpoofFunc(old_fs_attributes)

debug.setupvalue(fs.isDriveRoot, 2, _G.fs)

settings.load()

-- Load old motd (TODO: patch env escape) --
if not motd_disabled then
    shell.run("motd")
end

-- Continue with standard startup --
