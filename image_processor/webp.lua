function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end


local newFile = ngx.var.request_filename;
local newFile = string.gsub(newFile, "webp/", "");
local originalFile = newFile:sub(1, #newFile - 5);
-- ngx.log(ngx.STDERR, "uri:", originalFile)
if not file_exists(originalFile) then
    ngx.exit(ngx.HTTP_NOT_FOUND);
    return
end
-- cwebp -q 50 image.jpg -o image.webp
excute_cmd = "cwebp -q 60 " .. originalFile .. " -o " .. newFile
os.execute(excute_cmd);

if file_exists(newFile) then
    ngx.exec(ngx.var.uri);
else
    file = io.open("/tmp/file.log", "a")
    file:write("\n")
    file:write(excute_cmd)
    file:write("\n")
    file:write(originalFile)
    file:write("\n")
    file:write(newFile)
    file:write("\n")
    file:close()
    ngx.exit(ngx.HTTP_NOT_FOUND);
end