local debug = ({...})[1] or false
local _c = 0
local _g = 4
local g = {
    utils = "gbus",
    globals = "cli_names",
    consts = "c_prio",
    enums = "net_str",
}

for i,v in pairs(getgc(true)) do
    if _c == _g then break end
    if type(v) == "table" then
        for i2,v2 in pairs(g) do
            if c_ == _g then break end
            if rawget(v, v2) then
                if debug then print("HOOKED", i2, v) end
                g[i2] = v
                _G[i2] = v
                _c = _c + 1
                break
            end
        end
    end
end