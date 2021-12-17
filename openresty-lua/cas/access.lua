-- access_by_lua_file:
local cjson = require("cjson");

local req_headers = ngx.req.get_headers() -- 请求头
local resp_headers = ngx.resp.get_headers() -- 响应头

local uri_args = ngx.req.get_uri_args()

-- ngx.log(ngx.ERR, "header_filter_by_lua::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR, "header_filter_by_lua::::出参resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")

-- 替换请求参数
if uri_args["service"] then
    -- 替换外网IP，需在server或location中设置以下两个变量
    -- set $outerIP "100%.100%.100%.100"; # 外网IP
    -- set $insideIP  "172%.16%.0%.91"; # 内网IP
    uri_args["service"] = string.gsub(uri_args["service"], ngx.var.outerIP, ngx.var.insideIP)
    ngx.req.set_uri_args(uri_args)
end

if string.match(req_headers.host, ngx.var.outerIP) then
    -- ngx.req.set_header("Host", string.gsub(req_headers.host, ngx.var.outerIP, ngx.var.insideIP))
    -- ngx.req.set_header("X-Real-IP", "172.16.0.91")
    -- ngx.var.remote_addr = "172.16.0.91"
end
