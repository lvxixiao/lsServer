--- 将表dump成字符串(便于人类阅读的格式,支持环状引用)
function table.dump(t,iterDepth)
    if type(t) ~= "table" then
        return tostring(t)
    end
    local name = ""
    local cache = { [t] = "."}
    local function _dump(t,space,name, depth)
		if iterDepth and depth > iterDepth then
			return space .. tostring(t) .. "(max depth)."
		end

        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if type(k) == "number" then
                key = "[".. k .."]"
            end
            if cache[v] then
                table.insert(temp, space .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
				if next(v) then
                	table.insert(temp, space .. key .. " = {\n" .. _dump(v,space ..  string.rep(" ", 4) ,new_key, depth + 1) .. "\n" .. space .. "},")
				else
					table.insert(temp, space .. key .. " = {},")
				end
            else
                if type(v) == "string" then
                    v = "\"" .. v .."\""
                end
                table.insert(temp, space .. key .. " = " .. tostring(v) ..",")
            end
        end
        return table.concat(temp,"\n")
    end
    return "{\n" .._dump(t,"  ",name, 1) .. "\n}"
end

--- 浅拷贝
local function simpleCopy(node)
	if type(node) ~= "table" then return node end

	local newtable = {}
	local stack = {node, newtable}
	local tail = #stack
	local head = 1
	while head <= tail do
		local source = stack[tail-1]
		local dest = stack[tail]
		tail = tail - 2
		for k, v in pairs(source) do
			if type(v) == "table" then
				local nv = {}
				dest[k] = nv
				stack[tail + 1] = v
				stack[tail + 2] = nv
				tail = tail + 2
			else
				dest[k] = v
			end
		end
	end
	return newtable
end


table.simpleCopy = simpleCopy

string.split = function(s, delim, number)
    local split = {}
    if delim:len() == 1 then
        local pattern = "[^" .. delim .. "]*"
        string.gsub(s, pattern, function(v)
                                            if number then
                                                v = tonumber(v) or v
                                            end
                                            table.insert(split, v)
                                end
                )
    else
        split = Split(s, delim)
    end
    return split
end