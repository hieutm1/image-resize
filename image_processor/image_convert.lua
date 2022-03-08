local redis = require "resty.redis"
local magick = require("magick.wand")
 
local redis_client = redis:new()
local args = ngx.req.get_uri_args()
local image_service = args['s']
 
ngx.log(ngx.INFO, "uri:", ngx.var.uri)
ngx.log(ngx.INFO, "image service:", image_service)
 
redis_client:set_timeout(1000)
local ok,err = redis_client:connect('172.17.0.4',6379)
if not ok then
    ngx.log(ngx.ERR, "connect redis failed!")
    ngx.say("connect redis failed!")
    ngx.exit(0)
end
local url = ngx.var.http_host
local sub = url:match("[^.]*")
ngx.log(ngx.INFO, "sub:", sub)
ngx.log(ngx.INFO, "uri:", ngx.log(ngx.INFO, "sub:", sub))
local source = '/var/www/origin/'..sub..'/'..ngx.var.uri
ngx.log(ngx.INFO, "source:", source)
if image_service == nil then
    -- image origin
    local file = io.open(source); 
    local source_image = file:read("*all")
    file:close()
    ngx.log(ngx.INFO, "get source image!")
    ngx.say(source_image)
 
elseif image_service == "thumb" then
    -- thumb drop, resize
    local img = assert(magick.load_image(source))
 
    -- args
    local image_action = args['a']
 
    -- get from cache
    local cache_key = image_service..ngx.var.uri..image_action
    local res, err = redis_client:get(cache_key)
    if getmetatable(res) ~= nil then
        -- cache hit
        ngx.log(ngx.INFO, image_service, ", cache hit! cache key: ", cache_key)
        ngx.say(res)
        ngx.exit(0)
    end
 
    -- cache miss
    local output = nil 
    ngx.log(ngx.INFO, image_service, ", source: ", source, ", args, image action: ", image_action)
    -- ngx.say("start thumb...")
    imageblob = magick.thumb(source, image_action, output)
 
    -- set to cache
    redis_client:set(cache_key, imageblob)
    if not ok then
        ngx.log(ngx.ERR, "cache set failed! err:", err)
    else
        ngx.log(ngx.INFO, "cache set OK!")
    end
 
    -- response
    ngx.say(imageblob)
 
elseif image_service == "resize" then
    -- resize
    -- args, width, height
    local width = tonumber(args['w'])
    local height = tonumber(args['h'])
 
    -- source info
    local img = assert(magick.load_image(source))
    ngx.log(ngx.INFO, "source width:", img:get_width(), "source height:", img:get_height());
    ngx.log(ngx.INFO, image_service, ", arg, width:", width, ", height:", height)
    -- ngx.say("start resize...")
 
    img:resize(width, height)
    ngx.say(img:get_blob())
 
elseif image_service == "rotate" then
    -- rotate
    -- args, degrees
    local degrees = tonumber(args['d'])
 
    local img = assert(magick.load_image(source))
    img:rotate(degrees)
    ngx.say(img:get_blob())

elseif image_service == "blur" then
    -- blur
    -- args, sigma
    local sigma = tonumber(args['i'])
 
    local img = assert(magick.load_image(source))
    img:blur(sigma)
    ngx.say(img:get_blob())

elseif image_service == "sharpen" then
    -- sharpen
    -- args, sigma
    local sigma = tonumber(args['i'])
 
    local img = assert(magick.load_image(source))
    img:sharpen(sigma)
    ngx.say(img:get_blob())

elseif image_service == "quality" then
    -- quality
    -- args, quality
    local quality = tonumber(args['q'])
 
    local img = assert(magick.load_image(source))
    img:set_quality(quality)
    ngx.say(img:get_blob())

elseif image_service == "scale" then
    -- scale
    -- args, width, height
    local width = tonumber(args['w'])
    local height = tonumber(args['h'])
 
    -- source info
    local img = assert(magick.load_image(source))
    ngx.log(ngx.INFO, "source width:", img:get_width(), "source height:", img:get_height());
    ngx.log(ngx.INFO, image_service, ", arg, width:", width, ", height:", height)
    -- ngx.say("start scale...")
 
    img:scale(width, height)
    ngx.say(img:get_blob())
 
elseif image_service == "coalesce" then
    -- coalesce
 
    local img = assert(magick.load_image(source))
    img:coalesce()
    ngx.say(img:get_blob())

elseif image_service == "crop" then
    -- crop
    -- args, width, height
    local width = tonumber(args['w'])
    local height = tonumber(args['h'])
    local x = tonumber(args['x'])
    local y = tonumber(args['y'])
 
    -- source info
    local img = assert(magick.load_image(source))
    ngx.log(ngx.INFO, "source width:", img:get_width(), "source height:", img:get_height());
    ngx.log(ngx.INFO, image_service, ", arg, width:", width, ", height:", height)
    -- ngx.say("start crop...")
 
    img:crop(width, height, x, y)
    ngx.say(img:get_blob())

elseif image_service == "composite" then
    -- composite
    -- args, x, y 
    local img = assert(magick.load_image(source))
    local x = tonumber(args['x'])
    local y = tonumber(args['y'])
    local src = '/var/www/origin/'..sub..'/'..args['a']
    local compose = args['c']
    img:composite( assert(magick.load_image(src))  , x , y , compose)
    ngx.say(img:get_blob())

elseif image_service == "crop_resize" then
    -- crop_resize   
    -- args, width, height
    local width = tonumber(args['w'])
    local height = tonumber(args['h'])
    local img = assert(magick.load_image(source))
    img:resize_and_crop(width, height)
    ngx.say(img:get_blob())

else
    ngx.say("unknow image service!")
end
