local cjson = require "cjson"
local limit_traffic = require "resty.limit.count"

local config_file_path = "/usr/local/openresty/lua/rate_limit.json"

local shared_config_cache = ngx.shared.config_cache

-- Mem zones map 
local mem_zone_map = {
    [1] = "api_limit_zone_1",   -- Rate limit 1 requests per second
    [5] = "api_limit_zone_5",   -- Rate limit 5 requests per second
    [10] = "api_limit_zone_10", -- Rate limit 10 requests per second
}

-- Function to read theconfiguration file
local function read_config_file(path)
    local file = io.open(path, "r")
    if not file then
        ngx.log(ngx.ERR, "Error: Unable to open configuration file: ", path)
        return nil
    end

    local content = file:read("*all")
    file:close()

    local config = cjson.decode(content)
    return config
end

-- Function to load configuration into memory cache
local function load_config()
    local cached_config = shared_config_cache:get("rate_limits")
    if cached_config then
        return cjson.decode(cached_config)
    end

    local config = read_config_file(config_file_path)
    if not config then
        ngx.log(ngx.ERR, "Error reading the config file.")
        return nil
    end

    -- Store in cache by 1 hour
    shared_config_cache:set("rate_limits", cjson.encode(config), 3600)

    return config
end


local config = load_config()

if not config then
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

-- Get API key from request header
local api_key = ngx.req.get_headers()["Authorization"]
if not api_key then
    api_key = "DEFAULT"
end

-- Get the rate limit for the API key
local rate_limit = config[api_key] or config["DEFAULT"] -- Default rate limit if key is not in the config file

-- Get mem zone
local mem_zone_name = mem_zone_map[rate_limit] or "api_limit_zone_1"

ngx.log(ngx.DEBUG, "Creating limiter zone " .. mem_zone_name .. " for rate limit " .. rate_limit .. ".")

-- Create a limiter instance using the rate limit
local lim, err = limit_traffic.new(mem_zone_name, rate_limit, 1)  -- 1 second window
if not lim then
    ngx.log(ngx.ERR, "Failed to create limiter for rate limit " .. rate_limit .. ": ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end


local key = "api_key:" .. api_key  
local current, err = lim:incoming(key, true)

if not current then
    if err == "rejected" then
        ngx.status = ngx.HTTP_TOO_MANY_REQUESTS
        ngx.say("Rate limit exceeded.")
        ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
    else
        ngx.log(ngx.ERR, "Failed to check rate limit: ", err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
end

ngx.log(ngx.DEBUG,"Request allowed, API Key: " .. api_key)
