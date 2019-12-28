core.register_fetches("backend_select", function(txn)
    for k,v in pairs(core.backends) do
      local servs = v.servers
      for sk,sv in pairs(servs) do
        core.Debug(sk)
        local svAddr = sv.get_addr(sv)
        local isMaster = checkMongo(svAddr)
        if (isMaster)
        then
      core.Debug("###### Now primary instance is:"..svAddr)
          return k
        end
      end
    end
  end)
  
  checkMongo = function(mongosvr)
    core.Debug("###### checkMongo mongo address ::"..mongosvr)
    local mongo = require 'mongo'
    local client = mongo.Client('mongodb://'..mongosvr)
    local isp = client:command('admin','{ "isMaster": "1" }')
    local bson = mongo.BSON{}
    pcall(function()
        bson:concat(isp)
      end)
    local ispri=bson:find('ismaster')
    if unexpected_condition then error() end
    return ispri
  end