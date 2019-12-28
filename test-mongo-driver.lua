checkMongo = function(mongosvr)
    print("#############"..mongosvr)
    local mongo = require 'mongo'
    local conn = 'mongodb://'..mongosvr
    local client = mongo.Client(conn)
    local isp = client:command('admin','{ "isMaster": "1" }')
    local bson = mongo.BSON{}
    if pcall(function()
        bson:concat(isp)
         end)
    then
        print("mongo driver connection right...")
    else
        print("mongo driver connection error...")
    end
    local ispri=bson:find('ismaster')
    print("Is master :"..tostring(ispri))
    return ispri
  end
  
  if checkMongo("192.168.0.3:27017") then
    print("192.168.0.3:27017 is master...")
  else
    print("192.168.0.3:27017 is not master...")
  end