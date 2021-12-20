-- header_filter_by_lua_file:
-- local cjson = require("cjson");

-- local req_headers = ngx.req.get_headers() -- 请求头
local resp_headers = ngx.resp.get_headers() -- 响应头
ngx.header.content_length = nil -- body_filter_by_lua*替换内容后需要置空内容长度

-- ngx.log(ngx.ERR, "header_filter_by_lua::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR, "header_filter_by_lua::::resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")

-- 替换返回响应头，需在server或location中设置以下变量
-- set $inHost "172.16.0.91"; # 内网IP
if ngx.header.location ~= nil
    -- 判断响应Host是否为客户端访问Host
    and not string.match(ngx.header.location, ngx.var.host)
    and ngx.var.inHost and ngx.var.inHost ~= nil
then
    -- 替换响应头中的外网IP
    local newstr, n, err = ngx.re.gsub(resp_headers.location, ngx.var.inHost, ngx.var.host, "i")
    -- ngx.log(ngx.ERR, "\n新字符: ", newstr, "\n老字符: ", resp_headers.location,"\n", ngx.var.host,"\n")
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

if resp_headers.refresh and ngx.var.inHost and ngx.var.inHost ~= nil then
    local newstr, n, err = ngx.re.gsub(resp_headers.refresh, ngx.var.inHost, ngx.var.host, "i")
    -- ngx.log(ngx.ERR, "\n新字符: ", newstr, "\n老字符: ", resp_headers.refresh,"\n", ngx.var.host,"\n")
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
