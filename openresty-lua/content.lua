-- content_by_lua_file
local cjson = require("cjson");
local resp_body = ngx.arg[1];
ngx.say("<p>hello, world</p>");
-- 响应体
ngx.ctx.buffered = (ngx.ctx.buffered or "") .. resp_body;
if (ngx.arg[2]) then
    ngx.ctx.resp_body = ngx.ctx.buffered;
end

local req_header = ngx.req.get_headers();
ngx.ctx.req_header = req_header;
ngx.req.read_body();
ngx.ctx.req_body = ngx.req.get_body_data();
ngx.log(ngx.ERR, "server: ", req_header);

local auth = 'Basic ' .. ngx.var.auth -- basic认证
if headers['authorization'] ~= auth then
    ngx.status = 401
    ngx.header['WWW-Authenticate'] = 'Basic realm="this is my domain"'
    ngx.say('Unauthorized')
else
    -- proxy传入一个'@'开头的location内部路径
    return ngx.exec(ngx.var.proxy)
end

local res = ngx.location.capture("/") -- 请求
if res then
    ngx.say("status: ", res.status)
    ngx.say("body:")
    ngx.print(res.body)
end

ngx.log(ngx.ERR, ngx.var.request_body)