module Dao
  class PathMap < ::Map
    def to_json(*args, &block)
      as_json.to_json(*args, &block)
    end

    def as_json
      inject(Map.new){|json, kv| json.update(json_key_for(kv.first) => kv.last)}
    end

    def json_key_for(key)
      Array(key).join('.').gsub(/\.(\d+)(\.)?/, '[\1]\2')
    end
  end
end


if $0 == __FILE__
  pm = Dao::PathMap.new
  pm[[:array, 0, :key]] = 'value'
  pm[[:key]] = 'value'
  p pm.as_json
end
