require 'rubygems'
require 'mongo'
require 'json'
include Mongo


def hashme(obj)
return JSON.parse(obj.to_a.to_json)
end
#conn = Mongo::Connection.new('localhost', 27017)
@db = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'testdata')
@sub  = @db[:subset]
@dataset=hashme(@sub.find())
@dataset.each{|el|
  if !el['sev1'] then
      el['sev1']=0
      el['sev2']=0
      el['sev3']=0
      el['sev4']=0
    end
  }

