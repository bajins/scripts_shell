-- access_by_lua_file: 进
local cjson = require("cjson");

local req_headers = ngx.req.get_headers() -- 请求头
local resp_headers = ngx.resp.get_headers() -- 响应头

local uri_args = ngx.req.get_uri_args()

-- ngx.log(ngx.ERR,"header_filter_by_lua::::req_headers请求头：》》》\n", cjson.encode(req_headers), "\n《《《")
-- ngx.log(ngx.ERR,"header_filter_by_lua::::出参resp_headers响应头：》》》\n", cjson.encode(resp_headers), "\n《《《")

-- 内网应用及IP，需在server或location中设置以下变量
-- set $hosts '{"cas":"172.16.0.91:28802","ims-bi":"172.16.0.91:28803"}';
-- 替换请求参数
if uri_args["service"] and ngx.var.hosts then
    local host = ""
    local hosts = cjson.decode(ngx.var.hosts)
    for k, v in pairs(hosts) do
        -- ngx.log(ngx.ERR,"\n", k, "===",v ,"\n")
        local from, to, err = ngx.re.find(uri_args["service"], k, "i")
        if from then
            host = v
            break
        end
    end
    if host == "" then
        return
    end
    -- ngx.req.set_header("X-Real-IP", string.gsub(host, ":.*", ""))
    local newstr, n, err = ngx.re.gsub(uri_args["service"], ngx.var.http_host, host, "i")
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
