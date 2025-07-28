# PG_V5系统内外网访问实现


## 应用背景

> 只部署一套V5系统，实现通过内部网络可以直接访问，也可以通过外部IP进行访问



## 实现思路

> 后端返回的地址全部填NGINX的内网IP:port（端口内外网一致），当为外网IP请求进来时，把URL替换成NGINX的内网IP，返回时替换请求头中的内网IP为外网IP


## 系统部署

1. `ims.properties`文件配置的`cas.server`和`cas.client`，都为内网NGINX地址和端口
2. 系统管理-系统配置的各个模块的主机地址都为内网NGINX地址和端口



## 实现步骤

> 此步骤是在已经通过`Deploy`项目部署的无端口访问方式基础上操作的！


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

**[`lua-nginx-module`时序图](https://github.com/openresty/lua-nginx-module#lua_load_resty_core)，点击链接后向上滑动**

> lua脚本总共有三个，需要分别把：`access.lua`、`body_filter.lua`、`header_filter.lua`等文件到`/usr/local/openresty`目录；



### 修改V5系统应用中nginx的配置文件

- 在需要外网访问系统的nginx配置文件`ims-*-app.conf`中，配置lua脚本的路径

```conf
#lua_code_cache off; # 编译代码缓存，建议只在开发环境使用，默认on
access_by_lua_file /usr/local/openresty/access.lua;
header_filter_by_lua_file /usr/local/openresty/header_filter.lua;
body_filter_by_lua_file /usr/local/openresty/body_filter.lua;
```

**通过命令`nginx`启动，或通过命令`nginx -s reload`重启NGINX，如果没有报错，至此所有配置已完成；**

