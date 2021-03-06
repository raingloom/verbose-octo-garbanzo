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
local M = {}

local inspect = require 'inspect'

local getlocal, getinfo, getupvalue = debug.getlocal, debug.getinfo, debug.getupvalue
local stderr = io.stderr

function M.startREPL()
    require 'interlu'.interact()
end

function M.handler(...)
    stderr:write(inspect(M.collectinfo(3)))
    if M.dropToREPL then
        M.startREPL()
    end
    return ...
end

function M.collectinfo(stackindex)
    local levels = {}
    local stackindex = stackindex or 2
    local info
    repeat
        info = getinfo(stackindex)
        if info then
            local function localhelper(index,direction,tbl)
                local k, v
                repeat
                    k, v = getlocal(stackindex,index)
                    if k~=nil then
                        tbl[index*direction]={name=k,value=v}
                    end
                    index = index + direction
                until k==nil
            end

            local varargs = {}
            local locals = {}

            localhelper(1,1,locals)
            localhelper(-1,-1,varargs)

            local upvalues = {}

            do
                local upindex = 1
                local k, v
                repeat
                    k, v = getupvalue(info.func, upindex)
                    if k~=nil then
                        upvalues[upindex] = {name=k, value=v}
                    end
                    upindex=upindex+1
                until k==nil
            end
            
            levels[stackindex]={
                info=info,
                varargs=varargs,
                locals=locals,
                upvalues=upvalues,
            }
        end
        stackindex = stackindex + 1
    until info == nil
    return levels
end

return M
