-- header_filter_by_lua_file: 出
local cjson = require("cjson");

-- local req_headers = ngx.req.get_headers() -- 请求头
local resp_headers = ngx.resp.get_headers() -- 响应头
ngx.header.content_length = nil -- body_filter_by_lua*替换内容后需要置空内容长度

-- ngx.log(ngx.ERR,"header_filter_by_lua::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR,"header_filter_by_lua::::出参resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")


-- 内网应用及IP，需在server或location中设置以下变量
-- set $hosts '{"cas":"172.16.0.91:28802","ims-bi":"172.16.0.91:28803"}';
if not ngx.var.hosts or ngx.var.hosts == nil then
    return
end
local hosts = cjson.decode(ngx.var.hosts)
local host = ""
for k, v in pairs(hosts) do
    -- ngx.log(ngx.ERR,"\n", k, "===",v ,"\n")
    if host == "" then
        host = v
    else
        host = host.."|"..v
    end
end
if host == "" then
    return
end

-- 替换返回响应头
if ngx.header.location ~= nil
    -- and not string.match(ngx.header.location, ngx.var.http_host)
then
    -- 判断响应Host是否为客户端访问Host
    local from, to, err = ngx.re.find(ngx.header.location, ngx.var.http_host, "i")
    if from then
        return
    end
    -- 替换响应头中的外网IP   ngx.var.http_host
    local newstr, n, err = ngx.re.gsub(resp_headers.location, host, ngx.var.http_host, "i")
    -- ngx.log(ngx.ERR, "\n新字符: ", newstr,"\n老字符: ", resp_headers.location,"\n", host,"\n")
    if newstr then
         ngx.header['location'] = newstr
    else
        if err then
            ngx.say("error: ", err)
            ngx.log(ngx.ERR, "error: ", err)
            return
        end
        ngx.say("not matched!")
        return
    end
end

if resp_headers.refresh then
    local from, to, err = ngx.re.find(resp_headers.refresh, ngx.var.http_host, "i")
    if from then
        return
    end
    local newstr, n, err = ngx.re.gsub(resp_headers.refresh, host, ngx.var.http_host, "i")
    -- ngx.log(ngx.ERR, "\n新字符: ", newstr,"\n老字符: ", resp_headers.refresh,"\n", host,"\n")
    if newstr then
         ngx.header['refresh'] = newstr
    else
        if err then
            ngx.say("error: ", err)
            ngx.log(ngx.ERR, "error: ", err)
            return
        end
        ngx.say("not matched!")
        return
    end
end
