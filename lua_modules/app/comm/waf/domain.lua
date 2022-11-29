
local __ = { }

__.index = function()

    local sslx  = require "app.comm.sslx"
    local waf   = require "app.comm.waf"
    local cjson = require "cjson.safe"
    local dt    = require "app.utils.dt"

    local  html = waf.html("domain.html")
    if not html then ngx.exit(404) end

    local list = sslx.domain.load_domains()

    local domains = {}
    for _, d in ipairs(list) do
        local issuance_time = tonumber(d.issuance_time) or 0
        local expires_time  = tonumber(d.expires_time ) or 0

        table.insert(domains, {
            domain_name   = d.domain_name,
            dnspod_token  = d.dnspod_token,
            issuance_time = issuance_time > 0 and dt.to_date(issuance_time) or "",
            expires_time  = expires_time  > 0 and dt.to_date(expires_time ) or "",
        })
    end

    local g = cjson.encode {
        domains = domains,
    }

    html = string.gsub(html, "{ G }", g)

    ngx.header["content-type"] = "text/html"
    ngx.print(html)

end

__.certs = function()

    local sslx  = require "app.comm.sslx"

    local args = ngx.req.get_uri_args()

    local debug_mode = (args.mode == "debug")

    sslx.order.order_certs(debug_mode)

end

return __
