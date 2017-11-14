do
    local tracer = 'src.tracer'
    if not package.loaded[tracer] then
        tracer = require(tracer)
        return assert(
            xpcall(
                debug.getinfo(1).func,
                tracer.handler,
                ...
            )
        )
    end
end

local inspect = require 'inspect'

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

local function UH(...)
    local t = table.pack(...)
    for k,v in ipairs(t) do
        t[k]=v:gsub('[^%w%(%)]',function(c)return '&#'..c:byte()..';'end)
    end
    return table.unpack(t)
end

local function defget(t,k,d)
    local r = t[k]
    if r==nil then
        r = d
        t[k] = d
    end
    return r
end

local arrows = {}
local classmt = {}
function classmt:__index(k)
    if classmt[k]~=nil then
        return classmt[k]
    elseif k=='Fields' or k=='Methods' then
        local r={}
        self[k]=r
        return r
    end
end
function classmt:__call(t)
    assert(type(t)=='table')
    for k, v in pairs(t) do
        self[k] = v
    end
    return self
end
do
    for name, style in next, {
        depends = {shape = 'dashed', head = 'open'},
        associated = {shape = 'solid', head = 'open'},
        aggregates = {shape = 'solid', tail = 'diamond', dir = 'back'},
        contains = {shape = 'solid', tail = 'odiamond', dir = 'back'},
        specializes = {shape = 'solid', head = 'normal'},
        generalizes = {shape = 'solid', tail = 'normal', dir = 'back'},
        implements = {shape = 'dashed', tail = 'normal', dir = 'back'},
    } do
        classmt[name] = function(self, opt)
            local labels = opt.labels
            local done = {}
            for _, other in ipairs(opt) do
                if not done[other] then
                    --io.stderr:write('self=',inspect(self),',other=',inspect(other),'\n')
                    local head = '%s->%s['
                    local t = {}
                    for attr, val in pairs(style) do
                        attr = ({
                                head = 'arrowhead',
                                tail = 'arrowtail',
                               })[attr] or attr
                        t[#t+1] = attr .. '=' .. val
                    end
                    for attr, val in pairs(labels or {}) do
                        attr = ({
                                head = 'headlabel',
                                tail = 'taillabel',
                               })[attr] or attr
                        t[#t+1] = attr .. '=' .. UH(val)
                    end
                    arrows[#arrows+1]={fmt = head .. table.concat(t, ', ') .. ']', from = self, to = other}
                    done[other]=true
                end
            end
            return self
        end
    end
end

local weakkeys = {__mode='k'}

local env = {}
local builtins = {}
local envmt = {}
local envs = setmetatable({[env]=_ENV},weakkeys)
local vals = setmetatable({[env]={}},weakkeys)
do
    local t = {}
    local mt = {__index=t}
    function mt:__newindex(k,v)
        assert(t[k]==nil,'attempt to redefine WORM value')
        t[k]=v
    end
    setmetatable(vals,mt)
end

local modulemt = envmt
do
    local function wters(w)
        return function(c, filt)
            local t = c.Methods or {}
            for field, type in pairs(c.Fields or {}) do
                local ok
                if filt then
                    ok = filt[field]
                else
                    ok = true
                end
                if ok then
                    t[w..field:sub(1,1):upper()..field:sub(2)] = '('..type..')'
                end
            end
            c.Methods = t
        end
    end
    
    builtins.getters = wters 'get'
    builtins.setters = wters 'set'

    function builtins.Class(t)
        return setmetatable(t,classmt)
    end

    function builtins.Interface(t)
        t.interface = true
        return builtins.Class(t)
    end

    function builtins.Abstract(t)
        t.abstract = true
        return builtins.Class(t)
    end

    function builtins.Enum(t)
        local c = {}
        for _,k in ipairs(t) do
            c[k] = ''
        end
        return builtins.Class{Fields=builtins.public(c)}
    end

    do
        local envlevel = 0
        function envmt:__index(k)
            envlevel = envlevel + 1
            local function f()
                if k == 'Module' then
                    return function(t)
                        local r = setmetatable({},modulemt)
                        envs[r] = self
                        vals[r] = t
                        return r
                    end
                elseif vals[self][k]~=nil then
                    return vals[self][k]
                elseif builtins[k]~=nil then
                    return builtins[k]
                elseif _ENV[k]~=nil then
                    return _ENV[k]
                else
                    local r = envs[self][k]
                    if r~=nil then
                        return r
                    elseif envlevel == 1 then
                        local t = setmetatable({},classmt)
                        vals[self][k] = t
                        return t
                    end
                end
            end
            local r = f()
            envlevel = envlevel - 1
            return r
        end
    end

    function envmt:__newindex(k,v)
        if vals[self][k]~=nil then
            local val=vals[self][k]
            for vk,vv in pairs(v) do
                val[vk]=vv
            end
            setmetatable(val,getmetatable(v))
        else
            vals[self][k]=v
        end
    end

    function envmt:__pairs()
        return pairs(vals[self])
    end

    local function privacy(t,p)
        local r={}
        for k,v in pairs(t) do
            r[p..k]=v
        end
        return r
    end

    function builtins.private(t)
        return privacy(t,'-')
    end

    function builtins.public(t)
        return privacy(t,'+')
    end

    function builtins.combine(...)
        local r = {}
        for _,t in ipairs{...} do
            for k,v in pairs(t) do
                r[k]=v
            end
        end
        return r
    end

    setmetatable(env,envmt)
end

--local out = assert(io.open(arg[1],'w'))
--io.stderr:write(inspect(env))

local nodenames = setmetatable({},weakkeys)

local function procarrows(arrows)
    for _, arrow in ipairs(arrows) do
        local arrow = arrow
        L(
            string.format(
                arrow.fmt,
                assert(nodenames[arrow.from],'unnamed head'),
                assert(nodenames[arrow.to], 'unnamed tail')
            )
        )
    end
end

local function procclass(name, tbl, path)
    path:push(name)
    do
        nodenames[tbl] = path:concat('_')
        
        W(path:concat('_'))
        L '[label=<'
        L '<TABLE>'
        do
            W'<TR><TD>'
            if tbl.abstract then
                W('<I>',name,'</I>')
            elseif tbl.interface then
                L(UH('<<interface>>'),'<BR/>')
                W(name)
            else
                W(name)
            end
            L'</TD></TR>'
            HR()
            local function procfields(tbl, k)
                for fieldname, field in pairs( tbl[k] or {} ) do
                    W '<TR><TD ALIGN="LEFT">'
                    if k == 'Methods' then
                        W(UH(fieldname, field))
                    else
                        W(UH(fieldname), ':', UH(field))
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
    assert(path:pop()==name)
end

local function procmodule(name,env,path)
    path:push(name)
    do
        W 'subgraph cluster_'
        W (path:concat('_'))
        L ' {'
        W 'label=<<B>'
        W (UH(name))
        L '</B>>'
        for k, v in pairs(env) do
            if type(v) == 'table' then
                if getmetatable(v) == classmt then
                    procclass(k,v,path)
                elseif getmetatable(v) == modulemt then
                    procmodule(k,v,path)
                else
                    error 'unexpected data'
                end
            else
                error 'unexpected data'
            end
        end    
        L '}'
    end
    assert(path:pop()==name)
end

local function procroot(env,rootname)
    L 'digraph {'
    L 'node [shape=rect]'
    
    local path = {n=0}
    do
        function path:push(x)
            path[self.n+1],self.n = x,self.n+1
        end
        function path:pop()
            assert(self.n>0,'path stack underflow')
            local ret = self[self.n]
            self[self.n] = nil
            self.n = self.n-1
            return ret
        end
        function path:concat(s)
            return table.concat(self,s)
        end
        setmetatable(path,path)
    end

    procmodule(rootname,env,path)
    --error(inspect{arrows=arrows,env=env,nodenames=nodenames})
    procarrows(arrows)
    L '}'
end

assert(loadfile(arg[1],'t',env))()
procroot(env,'WebShoppe')
