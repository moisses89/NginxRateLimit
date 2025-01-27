# Start from the official OpenResty Alpine image
FROM openresty/openresty:alpine

# Install LuaRocks and OPM (OpenResty Package Manager)
RUN apk add --no-cache curl perl

# Install lua-resty-limit-traffic using opm
RUN opm install openresty/lua-resty-limit-traffic

# Expose OpenResty on port 80
EXPOSE 80
