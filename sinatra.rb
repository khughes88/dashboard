
require 'mongo'
include Mongo
require 'sinatra'
require 'json'
require 'logger'
enable :logging
require './config.rb'

set :public_folder, File.dirname(__FILE__)+"/"
set :environment, :production
set :protection, :except => :frame_options 
set :port, 80
#~ $logger = Logger.new('sinatra.log','weekly')
#~ $logger.level = Logger::WARN
#~ $stdout.reopen("sinatra.log", "w")
#~ $stdout.sync = true
#~ $stderr.reopen($stdout)

#Thread.new do # trivial example work thread
# system("run_schedule.rb")
#end

def hashme(obj)
return JSON.parse(obj.to_a.to_json)     
end

get '/log' do	
erb :log, :layout=>false
end

get '/' do	
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@dataset=hashme(@sub.find())
erb :dash, :layout=>false
end

get '/daily/:proj' do	 |proj|
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@dataset=hashme(@sub.find("projname"=>proj))[0]
p "Heyt: #{@dataset['hi_jiracurve']}"
erb :dash_daily, :layout=>false
end

get '/config' do
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']	
@dataset=hashme(@sub.find())
erb :config, :layout=>false
end

post '/config' do
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']	

d=Hash.new

d['jiraproject']=params[:jiraproject]
d['globalBacklog']=params[:globalBacklog]
d['qcid']=params[:qcid]
d['teamcitybuildurl']=params[:teamcitybuildurl]
d['teamcitybuildid']=params[:teamcitybuildid]
d['teamcitytesturl']=params[:teamcitytesturl]
d['teamcitytestid']=params[:teamcitytestid]
d['sprint_name']=params[:sprint_name]
d['sprint_start']=params[:sprint_start]
d['sprint_end']=params[:sprint_end]
p @sub.update({"projname"=>"#{params[:projname]}"}, {"$set" => d},  { "upsert"=> true })	
				
redirect '/config'	
end

post '/delete/:proj' do |proj|
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@super  = @db['superset']
@sub.remove({"projname"=>proj})
@super.remove({"projname"=>proj})
redirect '/config'
end

post '/newproj' do
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
data=Hash.new
data['sev1']
data["build"] = "none"
data["builddate"] = "1/1/2014"
data["buildnew"] = false
data["buildstatus"] = "unknown"
data["teststatus"] = "unknown"
data["testprogress"] = 0
data["current_sprint"] = "Not Sprinting"
data["days_remaining"] = 0
data["globalBacklog"] = "unknown"
data["hi_jiracurve"] = []
data["jiracurve_guide"] = []
data["jiracurveurl" ]= "https://www.citi.net/jira/secure/IssueNavigator!executeAdvanced.jspa?jqlQuery=project=0000 AND backlog='' AND type='5' AND status!='Closed'&runQuery=true&clear=true"
data["jiradefectsurl"] = "https://www.citi.net/jira/secure/IssueNavigator!executeAdvanced.jspa?jqlQuery=project=0000 AND fixVersion='CDT-R3-Backlog' AND type='5' AND status!='Closed'&runQuery=true&clear=true"
data["jiraproject" ]= "00000"
data["low_jiracurve"] = []
data["majors"] = 0
data["minors"] = 0
data["passpercentage"] = 0
data["project_days"] = []
data["qcid" ]= "0"
data["sev1"] = 0
data["sev1res"] = 0
data["sev2"] = 0
data["sev2res"] = 0
data["sev3" ]= 0
data[ "sev3res"] = 0
data["sev4"] = 0
data["sev4res"] = 0
data["sprints"] = []
data["sprint_name"] = "No Sprint"
data["sprint_start"] = "1/1/2014"
data["sprint_end"] = "1/1/2014"
@sub.insert({"projname"=>params[:newproj]})
@sub.update({"projname"=>"#{params[:newproj]}"}, {"$set" => data},  { "upsert"=> true })	
				
				
redirect '/config'	
end



