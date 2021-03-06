--[[
Copyright (C) 2017 Prónai Péter Emánuel

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.]]
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
        local s, i = {}, 1
        for _,c in utf8.codes(v) do
            s[i], i = '&#'..c..';', i + 1
        end
        t[k]=table.concat(s)
    end
    return table.unpack(t)
end

local function getdef(t,k,d)
    local r = t[k]
    if r==nil then
        r=d
        t[k]=r
    end
    return r
end

local function combine(...)
    local r = {}
    for _,t in ipairs{...} do
        for k,v in pairs(t) do
            r[k]=v
        end
    end
    return r
end

local function defget(t,k,d)
    local r = t[k]
    if r==nil then
        r = d
        t[k] = r
    end
    return r
end

local containers = {
    Set = true,
}

local arrows = {}
local classmt = {}
local combines = {}
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
local function autoarrowopt(op)
    local function fret()
        local labels = {}
        local opt = {labels=labels}
        local meth
        if op.func:peek() or op.tmpl:peek() then
            meth = 'depend'
            --labels.tail = opt.
        else
            if not op.reference:peek() then
                meth = 'contain'
            end
        end
        labels.head = op.mltplcty:peek()
        if op.container:peek() then
            labels.head = labels.head or '0..'
        end
        coroutine.yield(meth or 'depend', opt)
    end
    return coroutine.wrap(fret)
end
do
    for name, style in next, {
        depend = {shape = 'dashed', head = 'open'},
        associate = {shape = 'solid', head = 'open'},
        aggregate = {shape = 'solid', tail = 'odiamond', dir = 'back'},
        contain = {shape = 'solid', tail = 'diamond', dir = 'back'},
        specialize = {shape = 'solid', head = 'onormal'},
        generalize = {shape = 'solid', tail = 'onormal', dir = 'back'},
        implement = {shape = 'dashed', head = 'onormal', dir = 'back'},
    } do
        classmt[name] = function(self, opt)
            local labels = opt.labels
            for _, other in ipairs(opt) do
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
                    t[#t+1] = attr .. '="' .. UH(val)..'"'
                end
                arrows[#arrows+1]={fmt = head .. table.concat(t, ', ') .. ']', from = self, to = other}
            end
            return self
        end
    end
    do
        local specialize = classmt.specialize
        function classmt:specialize(opt)
            table.insert(combines,{self=self,opt=opt})
            return specialize(self,opt)
        end
    end
    do
        --mimic some of Rust's linear types
        do
            function classmt:own(opt)
                local l = defget(opt,'labels',{})
                l.head = '1'
                l.tail = '1'
                return self:contain(opt)
            end
            function classmt:ownsome(opt)
                local l = defget(opt,'labels',{})
                l.head = '1'
                l.tail = '1..*'
                return self:contain(opt)
            end
            function classmt:ownany(opt)
                local l = defget(opt,'labels',{})
                l.head = '1'
                l.tail = '0..*'
                return self:contain(opt)
            end
            function classmt:maybeown(opt)
                local l = defget(opt,'labels',{})
                l.head = '1'
                l.tail = '0..1'
                return self:contain(opt)
            end
        end
    end
end

local weakkeys = {__mode='k'}

local env = {}
local builtins = {}
local envmt = {}
local usings = {}
local classortkeys = {}
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

    do
        local sortkey = 1
        function builtins.Class(t)
            local r = setmetatable(t,classmt)
            classortkeys[r] = sortkey
            sortkey = sortkey + 1
            return r
        end
    end

    function builtins.Interface(t)
        t.interface = true
        return builtins.Class(t)
    end

    function builtins.Abstract(t)
        t.abstract = true
        return builtins.Class(t)
    end

    function builtins.Template(self,tmp)
        self.template = assert(tmp,'no template arguments')
        return self
    end

    function builtins.Enum(t)
        local c = {}
        for _,k in ipairs(t) do
            c[k] = ''
        end
        return builtins.Class{Fields=builtins.public(c)}
    end

    builtins.getdef = getdef

    do
        local envlevel = 0
        local usingdone
        function envmt:__index(k)
            envlevel = envlevel + 1
            if envlevel == 1 then
                usingdone = {}
            end
            local function f()
                if k == 'using' then
                    local function rf(opt)
                        local u = defget(usings,self,{})
                        for _, m in ipairs(opt) do
                            table.insert(u,m)
                        end
                    end
                    return rf
                elseif k == 'Module' then
                    return function(t)
                        local r = setmetatable({},modulemt)
                        envs[r] = self
                        vals[r] = t
                        usings[r] = {}
                        return r
                    end
                elseif vals[self][k]~=nil then
                    return vals[self][k]
                elseif builtins[k]~=nil then
                    return builtins[k]
                elseif _ENV[k]~=nil then
                    return _ENV[k]
                else
                    if not usingdone[self] then
                        usingdone[self] = true
                        for i, m in ipairs(defget(usings,self,{})) do
                            local r=m[k]
                            if r~=nil then
                                return r
                            end
                        end
                    end
                    do
                        local r = envs[self][k]
                        if r~=nil then
                            return r
                        end
                    end
                    do
                        if envlevel == 1 then
                            local t = builtins.Class({})
                            vals[self][k] = t
                            return t
                        end
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
    
    function builtins.hide(...)
        for _, t in ipairs{...} do
            t.hide = true
        end
        return ...
    end
    
    function builtins.id(...)
        return ...
    end

    builtins.combine = combine

    setmetatable(env,envmt)
end

--local out = assert(io.open(arg[1],'w'))
--io.stderr:write(inspect(env))

local nodenames = setmetatable({},weakkeys)

local grammar, grammart
do
    local lpeg = require 'lpeg'
    lpeg.locale(lpeg)

    local function node(tag,p)
        local function f(...)
            local r = {...}
            r.tag = tag
            return r
        end
        return p / f
    end

    local ws = lpeg.space^0
    

    local function N(t,p)
        local function f(...)
            local r = table.pack(...)
            r.tag = t
            r.n = nil
            return r
        end
        return p / f
    end

    local V,P,C = lpeg.V, lpeg.P, lpeg.C

    local function node(p,t)
        local function f(...)
            local r = {...}
            r.tag = t
            return r
        end
        return C(p) / f
    end

    local w = lpeg.space^0
    
    local id = w * node(lpeg.alpha * lpeg.alnum^0, 'id')
    local qid = w * node(id * (P'.' * id)^0, 'qid')
    local lp = w * P'('
    local rp = w * P')'
    local cln = w * P':'
    local arr = w * P'->'
    local cma = w * P','
    local amp = w * P'&'
    local lbr = w * P'['
    local rbr = w * P']'
    local lt = w * P'<'
    local gt = w * P'>'
    local num = w * node(lpeg.digit^1, 'num')
    local dd = w * P'..'
    local lrange = w * node(dd * num, 'lrange')
    local rrange = w * node(num * dd, 'rrange')
    local crange = w * node(num * dd * num, 'crange')
    local range = w * node(lrange + crange + rrange, 'range')
    local mltplcty = w * node(range + num, 'mltplcty')
    local comment = w * P'//' * -P''
    
    grammart = {
        type = node(V'templ' + V'func' + V'tuple' + V'reference' + V'array' + V'narray' + qid, 'type'),
        reference = node(amp * V'type', 'reference'),
        array = node(lbr * rbr * V'type', 'array'),
        narray = node(lbr * mltplcty * rbr * V'type', 'narray'),
        vfunc = lp * (V'params'^-1) * rp, 'vfunc',
        func = node(V'vfunc' * arr * V'type' + V'vfunc', 'func'),
        params = node(V'param' * (cma * V'param')^0, 'params'),
        param = node(id * cln * V'type', 'param'),
        types = node(V'type' * (cma * V'type')^0, 'types'),
        vtempl = lt * V'types'^-1 * gt,
        templ = node(qid * V'vtempl', 'templ'),
        tuple = node(lp * V'types'^-1 * rp, 'tuple'),
    }
    for k, v in pairs(grammart) do
        grammart[k] = w * v
    end
    grammart[1] = 'type'
    grammar = P(grammart)
end

local function procarrows(arrows)
    local set = {}
    for _, arrow in ipairs(arrows) do
        arrow = string.format(
            arrow.fmt,
            assert(nodenames[arrow.from],'unnamed head'),
            assert(nodenames[arrow.to], 'unnamed tail')
        )
        set[arrow] = true
    end
    for k in pairs(set) do
        L(k)
    end
end

local function procclass(name, tbl, path)
    if nodenames[tbl] or tbl.hide then
        return
    end
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
            elseif tbl.template then
                W(name,UH(tbl.template))
            else
                W(name)
            end
            if tbl.Comment then
                W('<BR/><I>//',UH(tbl.Comment),'</I><BR/>')
            end
            L'</TD></TR>'
            HR()
            local function procfields(tbl, k)
                for fieldname, field in pairs( tbl[k] or {} ) do
                    W '<TR><TD ALIGN="LEFT">'
                    local cfield, comment = field:match '(.-)(//.*)$'
                    if cfield then
                        field = cfield
                    else
                        comment = ' '
                    end
                    if k == 'Methods' then
                        W(UH(fieldname, field))
                    else
                        W(UH(fieldname), ':', UH(field))
                    end
                    W('<I>', UH(comment), '</I>')
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

local clustercount = 0
local clusteri = 0
local countclusters
do
    local done = {}
    function countclusters(env)
        if done[env] then
            return
        end
        done[env]=true
        for _, v in pairs(env) do
            if type(v) == 'table' and getmetatable(v) == modulemt then
                clustercount = clustercount + 1
                countclusters(v)
            end
        end
    end
end

local function procmodule(name,env,path)
    if nodenames[env] then
        return
    end
    path:push(name)
    nodenames[env]=path:concat('_')
    do
        W 'subgraph cluster_'
        L (path:concat('_'))
        W ' {'
        L 'style="filled"'
        do
            local color = {}
            for k, v in ipairs{clusteri / clustercount, 0.1, 1.0, 1.0} do
                color[k] = ('%.03f'):format(v)
            end
            color = table.concat(color,' ')
            L('fillcolor="',color,'"')
            clusteri = clusteri + 1
        end
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

local function autoarrows(env)
    local function qidcat(ast)
        local r = ast[1]:gsub('%s+',''):gsub('%.','_')
        return r
    end
    
    local done = {}

    local cls

    local function resolve(env, qid)
        local r = env
        for i = 2, #qid do
            r=r[qid[i][1]]
        end
        return r
    end
    
    local function pass1(env)
        if done[env] then
            return
        end
        done[env]=true
        local astdepth = 0
        local op = {}
        do
            local stackmt = {}
            stackmt.__index = stackmt
            local function mkstack()
                return setmetatable({n=0},stackmt)
            end
            function stackmt:push(x)
                self[self.n + 1], self.n = {x, astdepth}, self.n + 1
            end
            function stackmt:pop()
                assert(self.n>0,'tag stack underflow')
                local r = self[self.n]
                self[self.n] = nil
                self.n = self.n - 1
                return table.unpack(r)
            end
            function stackmt:peek()
                return table.unpack(self[self.n] or {})
            end
            local opmt = {}
            function opmt:__index(k)
                self[k] = mkstack()
                return self[k]
            end
            setmetatable(op,opmt)
        end
        local function astpass(ast)
            --io.stderr:write(inspect({ast=ast,op=op}),'\n')
            astdepth = astdepth + 1
            if ast.tag == 'qid' then
                for meth, opt in autoarrowopt(op) do
                    local other = resolve(env,ast)
                    opt[1] = other
                    cls[meth](cls,opt)
                end
            else
                local cntnr
                if ast.tag=='tmpl' then
                    if qidcat(containers[ast[1][1]]) then
                        cntnr = ast[1][1]
                    end
                end
                op[ast.tag]:push(ast[1])
                if cntnr then
                    op.container:push(cntnr)
                end
                for i = 2, #ast do
                    astpass(ast[i])
                end
                op[ast.tag]:pop()
                if cntnr then
                    op.container:pop()
                end
            end
            astdepth = astdepth - 1
        end
        local function procfields(fld)
            for nm, ty in pairs(fld) do
                ty = ty:gsub('%s*%/%/.-$','')
                if #ty > 0 then
                    local ast = grammar:match(ty)
                    if ast then
                        local _ = ast[1] == ty or error(string.format('failed to completely parse type\n#%q > #%q', ty, ast[1]))
                        astpass(ast)
                    end
                end
            end
        end
        for _, v in pairs(env) do
            if type(v) == 'table' then
                if getmetatable(v) == classmt then
                    cls = v
                    procfields(v.Fields or {})
                    procfields(v.Methods or {})
                elseif getmetatable(v) == modulemt then
                    pass1(v)
                else
                    error 'unexpected data'
                end
            else
                error 'unexpected data'
            end
        end
    end
    pass1(env)
end

local function proccombines()
    for _, cmb in ipairs(combines) do
        for _, field in ipairs{'Fields', 'Methods'} do
            local fld = cmb.self[field]
            assert(cmb.self[field] == fld and fld ~= nil)
            for _, cls in ipairs(cmb.opt) do
                for k, v in pairs(cls[field] or {}) do
                    fld[k] = v
                end
            end
        end
    end
end

local descplaintext
do
    local done = {}
    function descplaintext(name,env,fout,depth)
        name = nodenames[env]:gsub('_','.')
        if done[env] then
            return
        end
        done[env]=true
        depth = depth or 2
        local modules={}
        fout:write'\n' --just to be safe
        fout:write('\n',('#'):rep(depth),' ',name,'\n\n')
        for name, env in pairs(env) do
            if type(env) == 'table' then
                if getmetatable(env) == modulemt then
                    table.insert(modules,{name,env,fout,depth+1})
                elseif getmetatable(env) == classmt then
                    fout:write(' - ',env.interface and '*template* ' or '','**',name,env.template or '','**')
                    local comment = env.Comment
                    if comment then
                        fout:write(' *',comment,'*')
                    end
                    fout:write'\n'
                    local desc = env.Desc
                    if desc then
                        fout:write('\n    > *',desc,'*\n')
                    end
                    local function procfield(fld)
                        local t = env[fld]
                        for k, v in pairs(t or {}) do
                            fout:write('\n   - ',k,fld == 'Methods' and '' or ':',v,'\n')
                        end
                    end
                    procfield'Fields'
                    procfield'Methods'
                    fout:write'\n'
                end
            end
        end
        for _, args in ipairs(modules) do
            descplaintext(table.unpack(args))
        end
    end
end

local function filterroot(env)
    local hiddenset = {}
    local hidefrom = {}
    local hideto = {}
    local ok = {}
    local function filterenv(env)
        if ok[env] then
            return
        end
        ok[env]=true
        for _, t in pairs(env) do
            if getmetatable(t)==modulemt then
                filterenv(t)
            elseif getmetatable(t)==classmt then
                if t.hide then
                    hiddenset[t]=true
                end
                if t.hideto then
                    hideto[t]=true
                end
                if t.hidefrom then
                    hidefrom[t]=true
                end
            end
        end
    end
    filterenv(env)
    io.stderr:write(inspect{hiddenset=hiddenset})
    local dellist = {}
    for i, arrow in ipairs(arrows) do
        if hiddenset[arrow.from] or hiddenset[arrow.to] then
            table.insert(dellist,i)
        end
    end
    for o, i in ipairs(dellist) do
        --TRICKY STUFF!!!
        --we are modifying an array in-place so the original indices need to be shifted!
        table.remove(arrows,i-o+1)
    end
end

local function procroot(env,rootname)
    L 'digraph {'
    L 'encoding="UTF-8"'
    L 'splines=polyline'
    L 'stylesheet="style.css"'
    L 'node [shape=rect, style=filled]'
    
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
    proccombines()
    --autoarrows(env)
    filterroot(env)
    countclusters(env)
    procmodule(rootname,env,path)
    procarrows(arrows)
    descplaintext(rootname,env,assert(io.open('out/plaintext','w')))
    L '}'
end

assert(loadfile(arg[1],'t',env))()
procroot(env,'WebShoppe')
