-- header_filter_by_lua_file:
local cjson = require("cjson");

local req_headers = ngx.req.get_headers() -- 请求头
local resp_headers = ngx.resp.get_headers() -- 响应头
ngx.header.content_length = nil -- body_filter_by_lua*替换内容后需要置空内容长度

-- ngx.log(ngx.ERR, "header_filter_by_lua::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR, "header_filter_by_lua::::出参resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")

-- 替换返回响应头
if ngx.header.location ~= nil
    -- 判断响应Host是否为客户端访问Host
    and not string.match(ngx.header.location, ngx.var.http_host)
then
    -- 替换响应头中的外网IP，需在server或location中设置以下两个变量
    -- set $outerIP "100%.100%.100%.100"; # 外网IP
    -- set $insideIP  "172%.16%.0%.91"; # 内网IP
    ngx.header['location'] = string.gsub(resp_headers.location, ngx.var.insideIP, ngx.var.outerIP)
end

if resp_headers.refresh then
    ngx.header['refresh'] = string.gsub(resp_headers.refresh, ngx.var.insideIP, ngx.var.outerIP)
end
