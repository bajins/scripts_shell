# 系统内外网访问实现


## 应用背景

> 只部署一套V5系统，实现通过内部网络可以直接访问，也可以通过外部IP进行访问



## 实现思路

> 后端返回的地址全部填NGINX的内网IP:port（端口内外网一致），当为外网IP请求进来时，把URL替换成NGINX的内网IP，返回时替换请求头中的内网IP为外网IP



## 实现步骤

> 此步骤是在已经通过`Deploy`项目部署的无端口访问方式基础上操作的！


### 系统部署

1. `ims.properties`文件配置的`cas.server`和`cas.client`，都为内网NGINX地址和端口
2. 系统管理-系统配置的各个模块的主机地址都为内网NGINX地址和端口



### 安装OpenResty


> 需要先卸载已经安装的NGINX！把配置文件`nginx.conf`备份！


> 由于OpenResty是在NGINX基础上自定义开发，故不需要单独安装NGINX。

* 官方安装教程 [https://openresty.org/cn/installation.html](https://openresty.org/cn/installation.html)
* 预编译安装包 [https://openresty.org/cn/linux-packages.html](https://openresty.org/cn/linux-packages.html)


**安装命令：**

> 注：对于 CentOS 8 及更新版本，需要将`yum`命令替换成`dnf`执行。

```bash
# 切换当此目录，添加OpenResty仓库
cd /etc/yum.repos.d
# 下载仓库
wget https://openresty.org/package/centos/openresty.repo
# 更新yum源
yum check-update
# 安装openresty
yum install -y openresty
```

> OpenResty的安装路径为：`/usr/local/openresty`。在`openresty`目录下含nginx目录。


**添加NGINX变量**

> 通过openresty安装后，nginx的未添加到环境变量中，需要手动添加；

```bash
PATH=/usr/local/openresty/nginx/sbin:$PATH
export PATH
```


**配置NGINX**

> 把之前备份的配置覆盖到`/usr/local/openresty/nginx/conf`目录下，并做以下修改：

```bash
# 编辑配置文件
vim /usr/local/openresty/nginx/conf
# 在server块中添加Lua脚本执行时需要的变量
set $inHost "172.16.0.91"; # 内网IP
```



### 配置Lua脚本


> lua脚本总共有三个，需要分别把以下代码复制保存为：`access.lua`、`body_filter.lua`、`header_filter.lua`等文件到`/usr/local/openresty`目录；


**access.lua**

```lua
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
    local newstr, n, err = ngx.re.gsub(uri_args["service"], ngx.var.http_host, ngx.var.inHost, "i")
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

if string.match(req_headers.host, ngx.var.outerIP) and ngx.var.inHost and ngx.var.inHost ~= nil then
    -- ngx.req.set_header("Host", string.gsub(req_headers.host, ngx.var.http_host, ngx.var.inHost))
    -- ngx.req.set_header("X-Real-IP", "172.16.0.91")
    -- ngx.var.remote_addr = "172.16.0.91"
end
```


**header_filter.lua**

```lua
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
    and not string.match(ngx.header.location, ngx.var.http_host)
    and ngx.var.inHost and ngx.var.inHost ~= nil
then
    -- 替换响应头中的外网IP
    local newstr, n, err = ngx.re.gsub(resp_headers.location, ngx.var.inHost, ngx.var.http_host, "i")
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

if resp_headers.refresh and ngx.var.inHost and ngx.var.inHost ~= nil then
    local newstr, n, err = ngx.re.gsub(resp_headers.refresh, ngx.var.inHost, ngx.var.http_host, "i")
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
```


**body_filter.lua**

```lua
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
        -- 判断响应Host是否为客户端访问Host
        and not string.match(whole, ngx.var.http_host)
        and ngx.var.inHost and ngx.var.inHost ~= nil
    then
        -- ngx.log(ngx.ERR,"body_filter_by_lua::::响应内容：》》》\n", whole, "\n《《《")
        -- 替换外网IP，需在server或location中设置以下变量
        -- set $inHost "172.16.0.91"; # 内网IP
        whole = string.gsub(whole, ngx.var.inHost, ngx.var.http_host)
        -- 重新赋值响应数据，以修改后的内容作为最终响应
    end
    ngx.arg[1] = whole
end
```



### 修改应用中的app.conf

- 在需要外网访问系统的nginx配置文件`ims-*-app.conf`中，配置lua脚本的路径

```conf
#lua_code_cache off; # 编译代码缓存，建议只在开发环境使用，默认on
access_by_lua_file /usr/local/openresty/access.lua;
header_filter_by_lua_file /usr/local/openresty/header_filter.lua;
body_filter_by_lua_file /usr/local/openresty/body_filter.lua;
```

**通过命令`nginx`启动，或通过命令`nginx -s reload`重启NGINX，如果没有报错，至此所有配置已完成；**

