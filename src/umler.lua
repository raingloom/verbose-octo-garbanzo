if not package.loaded.StackTracePlus then
    local STP = require 'StackTracePlus'
    return assert(
        xpcall(
            debug.getinfo(1).func,
            STP.stacktrace,
            ...
        )
    )
end


local inspect = require 'inspect'

local envmt = {}
local out = io.stdout

local function W(...)
    out:write(...)
end

local function L(...)
    out:write(...)
    out:write('\n')
end

local function HR()
    W '<TR><TD BGCOLOR="Black"></TD></TR>'
end

local classmt = {}
classmt.__index = classmt

function envmt:__index(k)
    if _ENV[k] then
        return _ENV[k]
    else
        local t = {}
        self[k] = t
        return t
    end
end

function envmt:__newindex(k,v)
    if true then
        v.name = k
        rawset(self,k,v)
    end
end

local arrows = {}

do
    for name, style in next, {
        depends = {shape = 'dashed', head = 'open'},
        associate = {shape = 'solid', head = 'open'},
        aggregates = {shape = 'solid', tail = 'diamond'},
        contains = {shape = 'solid', tail = 'odiamong'},
        specializes = {shape = 'solid', head = 'normal'},
        generalizes = {shape = 'solid', tail = 'normal'},
        implements = {shape = 'dashed', tail = 'normal'},
    } do
        classmt[name] = function(self, other, label, qhead, qtail)
            local head = self.name .. '->' .. other.name .. '['
            local t = {}
            for attr, val in pairs(style) do
                attr = ({
                        head = arrowhead,
                        tail = arrowtail,
                       })[attr] or attr
                t[#t+1] = attr .. '=' .. val
            end
            arrows[#arrows+1]=head .. table.concat(t, ',') .. ']'
        end
    end
end

local env = {}

function env.combine(...)
    local r = {}
    for _,t in ipairs{...} do
        for k,v in pairs(t) do
            t[k] = v
        end
    end
    return r
end

function env.Class(t)
    return setmetatable(t,classmt)
end

function env.Abstract(t)
    t.abstract = true
    return env.Class(t)
end

function env.Interface(t)
    t.interface = true
    return env.Class(t)
end

function wters(w)
    return function(c, filt)
        local t = c.Methods or {}
        for field, type in pairs(c.Fields or {}) do
            t[w..field:sub(1,1):upper()..field:sub(2)] = '('..type..')'
        end
        c.Methods = t
    end
end

env.getters = wters 'get'
env.setters = wters 'set'

setmetatable(env, envmt)
assert(loadfile(arg[1],'t',env))()

--local out = assert(io.open(arg[1],'w'))
--io.stderr:write(inspect(env))
io.stderr:write(inspect(env))

L 'digraph {'
L 'node [shape=rect]'
for name, tbl in pairs(env) do
    if type(tbl) == 'table' and getmetatable(tbl) == classmt then
        W(name) L '[label=<'
        L '<TABLE>'
        do
            W'<TR><TD>'
            if tbl.abstract then
                W('<I>',name,'</I>')
            else
                W(name)
            end
            L'</TD></TR>'
            HR()
            local function procfields(tbl, k)
                for fieldname, field in pairs( tbl[k] or {} ) do
                    local privacy, fieldname = fieldname:match('([%+%-]?)(.*)')
                    privacy = privacy == '' and (k == 'Fields' and '-' or '+') or privacy
                    W '<TR><TD ALIGN="LEFT">'
                    if k == 'Methods' then
                        W(privacy, fieldname, field)
                    else
                        W(privacy, fieldname, ':', field)
                    end
                    W '</TD></TR>'
                    W '\n'
                end
            end
            procfields(tbl, 'Fields')
            HR()
            procfields(tbl, 'Methods')
        end
        L '</TABLE>'
        L '>];'
        end
end

for _, arrow in ipairs(arrows) do
    L(arrow)
end

L '}'
