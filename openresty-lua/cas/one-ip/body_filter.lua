-- body_filter_by_lua_file:
-- 获取当前响应数据
local chunk, eof = ngx.arg[1], ngx.arg[2]
-- local cjson = require("cjson");

-- local req_headers = ngx.req.get_headers() -- 请求头
-- local resp_headers = ngx.resp.get_headers() -- 响应头

-- 定义全局变量，收集全部响应
if ngx.ctx.buffered == nil then
    ngx.ctx.buffered = {}
end

-- 如果非最后一次响应，将当前响应赋值
if chunk ~= "" and not ngx.is_subrequest then
    table.insert(ngx.ctx.buffered, chunk)
    -- 将当前响应赋值为空，以修改后的内容作为最终响应
    ngx.arg[1] = nil
end

-- 如果为最后一次响应，对所有响应数据进行处理
if eof then
    -- 获取所有响应数据
    local whole = table.concat(ngx.ctx.buffered)
    ngx.ctx.buffered = nil
    
    -- 内容有指定IP
    if whole
        and ngx.var.inHost and ngx.var.inHost ~= nil
        -- 判断响应Host是否为客户端访问Host
        and not string.match(whole, ngx.var.host)
    then
        -- ngx.log(ngx.ERR,"body_filter_by_lua::::响应内容：》》》\n", whole, "\n《《《")
        -- 替换外网IP，需在server或location中设置以下变量
        -- set $inHost "172.16.0.91"; # 内网IP
        local newstr, n, err = ngx.re.gsub(whole, ngx.var.inHost, ngx.var.http_host, "i")
        if newstr then
            -- 替换外网IP，重新赋值响应数据，以修改后的内容作为最终响应
            whole = newstr
        end
    end
    ngx.arg[1] = whole
end
