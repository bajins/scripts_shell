-- access_by_lua_file:
-- local cjson = require("cjson");

-- local req_headers = ngx.req.get_headers() -- 请求头
-- local resp_headers = ngx.resp.get_headers() -- 响应头

local uri_args = ngx.req.get_uri_args()

-- ngx.log(ngx.ERR, "header_filter::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR, "header_filter::::resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")

-- 替换请求参数，需在server或location中设置以下变量
-- set $inHost "172.16.0.91"; # 内网IP
if uri_args["service"] and ngx.var.inHost and ngx.var.inHost ~= nil then
    -- 替换外网IP
    local newstr, n, err = ngx.re.gsub(uri_args["service"], ngx.var.host, ngx.var.inHost, "i")
    if newstr then
        -- 替换外网IP ngx.var.http_host
         uri_args["service"] = newstr
    else
        if err then
            ngx.say("error: ", err)
            ngx.log(ngx.ERR, "error: ", err)
            return
        end
        ngx.say("not matched!")
        return
    end
    ngx.req.set_uri_args(uri_args)
end

-- if string.match(req_headers.host, ngx.var.host) and ngx.var.inHost and ngx.var.inHost ~= nil then
    -- ngx.req.set_header("Host", string.gsub(req_headers.host, ngx.var.host, ngx.var.inHost))
    -- ngx.req.set_header("X-Real-IP", "172.16.0.91")
    -- ngx.var.remote_addr = "172.16.0.91"
-- end
