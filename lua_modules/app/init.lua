
local __ = {}

local appx = require "app.comm.appx"

__.info = function()
    local pok, resty_info = pcall(require, "resty.info")
    if not pok then return ngx.exit(404) end
    resty_info.info()
end

__.monitor = function()
    require "app.comm.monitor".start()
end

__.auth = function()

    -- Nginx-Lua HTTP 401 认证校验
    -- http://chenxiaoyu.org/2012/02/08/nginx-lua-401-auth/

    -- 本机访问无需认证
    if ngx.var.remote_addr == "127.0.0.1" then return end

    local uid = ngx.var.remote_user
    local psw = ngx.var.remote_passwd  -- 读不到密码

    if uid=="nginx@openresty" then return end

    -- 检查账号密码
    if uid=="nginx" and psw=="openresty" then return end

    -- 返回 HTTP 401 认证输入框
    ngx.header.www_authenticate = [[Basic realm="Restricted"]]
    ngx.exit(401)

end

-- 帮助文档 v20.08.21 by Killsen ------------------
__.help = function()

    local  app_name = ngx.var.app_name
    local  act_type = ngx.var.act_type

    if not app_name then return ngx.exit(404) end
    if not act_type then return ngx.exit(404) end

    ngx.ctx.app_name = app_name
    ngx.ctx.act_type = act_type

    local app  = appx.new(app_name)
    if not app then return ngx.exit(404) end

        if act_type == "help"     then app:help()
    elseif act_type == "reload"   then app:reload()
    elseif act_type == "initdao"  then app:init_dao()
    elseif act_type == "initdaos" then app:init_daos()
    elseif act_type == "api"      then app:gen_api_code()
    elseif act_type == "api.d.ts" then app:gen_api_ts()
    elseif act_type == "api.js"   then app:gen_api_js()
    else
        ngx.exit(404)
    end

end

-- 程序入口 v20.08.21 by Killsen ------------------
__.main = function()

    -- 程序名称
    local  app_name = ngx.var.app_name
    if not app_name then return ngx.exit(404) end

    ngx.ctx.app_name = app_name

    local app  = appx.new(app_name)
    if not app then return ngx.exit(404) end

    app:action(ngx.var.uri)

end

-- 程序调试 v22.10.28 by Killsen ------------------
__.debug = function()

    -- 仅用于本机调试
    if ngx.var.remote_addr ~= "127.0.0.1" or
        ngx.var.http_user_agent ~= "sublime" then
        return ngx.exit(403)
    end

    -- 运行的lua文件
    local file_name = ngx.var.http_file_name
    if not file_name or file_name == "" then
        return ngx.exit(403)
    end

    -- 程序名称
    local app_name = ngx.var.http_app_name
    if app_name and app_name ~= "" then
        ngx.ctx.app_name = app_name
    end

    local pok, func

    if ngx.req.get_method() == "POST" then
        ngx.req.read_body()
        local codes = ngx.req.get_body_data()
        pok, func = pcall(loadstring, codes)
    else
        pok, func = pcall(loadfile, file_name)
    end

    if not pok then
        return ngx.say(func)
    end

    local pok, err = pcall(func)
    if not pok then
        return ngx.say(err)
    end

end

return __
