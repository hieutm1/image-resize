-- local url = "foo.bar.google.com"
-- local domain = url:match("[^.]*")
-- print(domain)    
excute_cmd = "cwebp -q 80 " .. "/var/www/origin/bcd/5.png" .. " -o " .. "/var/www/origin/bcd/5.webp"
os.execute(excute_cmd);