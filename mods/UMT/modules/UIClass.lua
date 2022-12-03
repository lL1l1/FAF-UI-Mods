--- Determines whether we have a simple class: one that has no base classes
local emptyMetaTable = getmetatable {}
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end

---@class SetupPropertyTable
---@field  set fun(class:fa-class, value:any)
---@field  get fun(class:fa-class): any

---@class PropertyTable
---@field  set fun(class:fa-class, value:any)
---@field  get fun(class:fa-class): any
---@field __property true

---@param setup SetupPropertyTable
---@return PropertyTable
function Property(setup)
    local getFunc = setup.get
    local setFunc = setup.set
    return {
        __property = true,
        set = setFunc,
        get = getFunc
    }
end

local function MakeProperties(class)
    local setProperties = {}
    local getProperties = {}
    for k, v in class do
        if type(v) == "table" then
            if v.__property then
                if v.get then
                    getProperties[k] = v.get
                end
                if v.set then
                    setProperties[k] = v.set
                end
            end

        end
    end
    if not table.empty(getProperties) then
        class.__index = function(self, key)
            if getProperties[key] then
                return getProperties[key](self)
            end
            return class[key]
        end
    end
    if not table.empty(setProperties) then
        class.__newindex = function(self, key, value)
            if setProperties[key] then
                return setProperties[key](self, value)
            end
            rawset(self, key, value)
        end
    end

    return class
end

local function CacheClassFields(classes, fields)
    local cache = {}
    for _, field in fields do
        cache[field] = {}
        for i, class in ipairs(classes) do
            cache[field][i] = class[field]
            class[field] = nil
        end
    end
    return cache
end

local function RestoreClassFields(classes, cache)
    for field, data in cache do
        for i, class in ipairs(classes) do
            class[field] = data[i]
        end
    end
end

local function MakeUIClass(bases, spec)
    local cache = CacheClassFields(bases, { "__newindex" })

    local class = Class(unpack(bases))
    if spec then
        class = class(spec)
    end
    RestoreClassFields(bases, cache)
    return MakeProperties(class)
end

function UIClass(...)
    if IsSimpleClass(arg) then
        return MakeUIClass(arg)
    end
    local bases = { unpack(arg) }
    return function(spec)
        return MakeUIClass(bases, spec)
    end
end
