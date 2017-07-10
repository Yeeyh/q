fns={}
mapArg={}
info=""
--字符串分割函数
--传入字符串和分隔符，返回分割后的table
function split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end
 
    return sub_str_tab;
end  

local function d2color(h)
	if type(h)=='string' then
		return h
	end
	s = string.format("%#x",tonumber(h,10))
	k,v = string.gsub(s,"0x(.)","%1")
	return k 
end
function i(k,v)
	mapArg[k]=v
end
function getData(k)
	return mapArg[k]
end

function sleep(n)
    local socket = require("socket")
    socket.select(nil, nil, n)
end
-----------------------------------------------------------------------------------

local win_w=1
local win_h=1
function setWinXH(x,h)
	win_w = x
	win_h = h
end

function getPixelColor(x, y)
	color = d2color(fns['getPixelColor'](x, y))
	return color
end
function findColor(x,y,x2,y,col,n)
	arr = fns['findColor'](x,y,x2,y,col,n)
	return arr[1],arr[2]
end
-- 多点取色
function cmpMultiCol(x,y,col,str,n)
    boo = false
    if cmpCol(x, y, col, n) then 
        boo = multiColor(x, y, str, n)
    else 
        boo = findMultiCol(x - 3, y - 3, x + 3, y + 3, col, str, n)
    end
    return boo
end
function cmpCol(x, y, col, n)

    x = x * win_w
    y = y * win_h
    local temp_col = getPixelColor(x, y)
    if temp_col==col then
        return true
    end
    return isCol(col, temp_col, n)
end

function multiColor(x,y,str,n)
    local arr1 = split(str, ",")
    for i,v in pairs(arr1) do
        local arr2 = split(v, "|")
        if not cmpCol(x+tonumber(arr2[1]),y+tonumber(arr2[2]),arr2[3],n) then
            return false
        end
    end
    return true
end
function findMultiCol(x1,y1,x2,y2,col,str,n)

    x1=x1*win_w
    y1=y1*win_h
    x2=x2*win_w
    y2=y2*win_h

    local x,y
    repeat
        intX,intY = findColor(x1,y1,x2,y2,col,n)
        if intX >= 0 then 
			
            if multiColor(intX,intY,str,n) then
                return true
            else
                x=intX
                y=intY
                while x < x2 do
                    intX,intY = findColor(x,y,x2,y,col,n)
					
                    if intX >= 0 then
                        if multiColor(intX,intY,str,n) then
                            return true
                        else
							--if 1 then return true end
                            x=intX+1
                        end
                    else
                        break
                    end
                end
                y1=y+1
            end
        else
            break
        end
    until y1 > y2
    return false
end
--16进制字符串，格式为"BBGGRR"
function colorToRGB(hex,rex)
	local red,green,blue
	if rex=="RRGGBB" then
		--RRGGBB
		red = tonumber(string.sub(hex, 1, 2),16)
		green = tonumber(string.sub(hex, 3, 4),16)
		blue = tonumber(string.sub(hex, 5, 6),16)
	else
		--BBGGRR
		red = tonumber(string.sub(hex, 5, 6),16)
		green = tonumber(string.sub(hex, 3, 4),16)
		blue = tonumber(string.sub(hex, 1, 2),16)
	end
    return red, green, blue  
end 
function isCol(col1, col2, n)
    local r1,g1,b1
    local r2,g2,b2
    r1,g1,b1 = colorToRGB(col1,"BBGGRR")
    r2,g2,b2 = colorToRGB(col2,"BBGGRR")
    if (1 - (math.abs(r1 - r2) + math.abs(g1 - g2) + math.abs(b1 - b2))) / 255 / 3 >= n then 
		return true
    end
	return false
end

function judge(v)
	local arr
	if type(v)=='string' then
		arr = getData(v)
	else
		arr = v
	end
	if arr == nil then return false end
	return cmpMultiCol(arr[1], arr[2], arr[3], arr[4], 0.9)
end
function click(v)
	local arr
	if type(v)=='string' then
		arr = getData(v)
	else
		arr = v
	end
	if arr == nil then return false end
	fns['click'](arr[1]*win_w,arr[2]*win_h)
end
-----------------------------------------------------------------------------------

function regMethod(name,fn)
	if type(fn) == "function" then
		fns[name]=fn
	end
end

function regMain(fn)
	regMethod("main",fn)
end
function regGetPixelColor(fn)
	regMethod("getPixelColor",fn)
end
function regFindColor(fn)
	regMethod("findColor",fn)
end
function checkMustFunc()
	if fns["main"]==nil then return "plese include main func" end
	if fns["getPixelColor"]==nil then return "plese include getPixelColor func" end
	if fns["findColor"]==nil then return "plese include findColor func" end
	return "success"
end

function reflect(fnName)
	if fns["before"] then 
		fns["before"]()
	end
	fns[fnName]()
	if fns["after"] then 
		fns["after"]()
	end
end


function exec(sleepTime)
	result = checkMustFunc()
	if not (result == "success") then 
		return result
	end
	while 1 do
		reflect("main")
		if sleepTime==nil then sleepTime=1 end
		sleep(sleepTime)
	end
end

local log = {}
function LogPath(path)
	log.path = path
end 
function OutLog(msg)
	local t = os.date("%H:%M:%S")
	local f = io.open(log.path,"a+")
	f:write(t.. "-\t"..msg.."\r\n")
    f:close()
end 

function debug()
	return info
end

-------------------------------------------------------按键
QMPlugin.exec = exec
QMPlugin.regMethod = regMethod
QMPlugin.regMain = regMain
QMPlugin.regGetPixelColor = regGetPixelColor
QMPlugin.regFindColor = regFindColor
QMPlugin.reflect = reflect
QMPlugin.LogPath = LogPath
QMPlugin.OutLog = OutLog
QMPlugin.setWinXH = setWinXH
--QMPlugin.cmpMultiCol = cmpMultiCol
QMPlugin.judge = judge
QMPlugin.click = click
QMPlugin.getData = getData
QMPlugin.i = i
QMPlugin.debug = debug