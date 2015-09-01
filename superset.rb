require 'mongo'
include Mongo
require 'selenium/server' 
include Selenium 
require 'watir-webdriver'
require 'xmlsimple'

require './config.rb'
require './subset.rb'
require 'json'


def jira_to_mongo
	
	@apps=''
	xml_out=''
	
	@server = Selenium::Server.new("selenium-server-standalone-2.39.0.jar", :background => true)
	@server << ["--additional", "-Xms1024m -Xmx1024m"]	
	@server.start 
	capabilities = WebDriver::Remote::Capabilities.firefox
	#capabilities = WebDriver::Remote::Capabilities.htmlunit(:javascript_enabled => true) 
	@b = Watir::Browser.new(:remote, :url => 'http://127.0.0.1:4444/wd/hub', :desired_capabilities => capabilities) 
	@b.driver.manage.timeouts.implicit_wait = 6000
	#Watir.default_timeout = 90
	#@b = Watir::Browser.new :firefox, :profile => 'default'
	
	begin
	
	@client = MongoClient.new('localhost', 27017)

@projects=hashme(@sub.find())
@projects.each{|project|
	
		if @apps.include?(project['jiraproject']) then
			p "#{Time.now+ (4*60*60)} data for #{project['jiraproject']}/#{project['projname']} already captured"
		else	
			@apps="#{@apps}<#{project['jiraproject']}>"
			p "#{Time.now+ (4*60*60)} getting latest jira data for #{project['projname']}"
				#jiraurl="https://www.citi.net/jira/sr/jira.issueviews:searchrequest-xml/temp/SearchRequest.xml?jqlQuery=project%3D#{project}"
				
				query="https://cedt-jira.nam.nsroot.net/jira/sr/jira.issueviews:searchrequest-xml/temp/SearchRequest.xml?jqlQuery=project+%3D+#{project['jiraproject']}+ORDER+BY+updated+DESC&tempMax=50"
				
				 jiraurl="https://cedt-jira.nam.nsroot.net/siteminderagent/forms/dssologinprod.fcc?TYPE=33554433&REALMOID=06-a398a018-2ad6-1053-a21c-84fb3af10000&GUID=&SMAUTHREASON=0&METHOD=GET&SMAGENTNAME=-SM-qm4R1yo7BsSIxAJTHGU%2fXn5VGLc8EXozb1jbsa1u389i6WVtKZ6dsc5mSVWD3GTIGohsWFPBVuIjk4hzgCr9xp1xS%2bljrnC2&TARGET=-SM-%2fjira"
						
				 @b.goto jiraurl
				sleep(2)
				#if @b.button(:id,'signonBtn').exists? then
					p "#{Time.now+ (4*60*60)} accessing Jira"
					@b.text_field(:name,'USER').when_present.set(@user)
					sleep(1)
					@b.text_field(:name,'PASSWORD').set(@pass)
					sleep(1)
					@b.button(:class,'ButtonSm').click
				#end
				sleep 5
				 @b.goto query
				p "#{Time.now+ (4*60*60)} waiting for response"
				count=0
				until @b.html.include?('XML representation of a search request') || count>30 || @b.html.include?('Bad request') 
					p "#{Time.now+ (4*60*60)} waiting for xml to load"
					sleep(10)
					count+=1
				end	
				if @b.html.include?('XML representation of a search request') then
					p "#{Time.now+ (4*60*60)} xml result presented in browser"
					xmlstr=@b.html
					
					
					p "#{Time.now+ (4*60*60)} parsing xml"
					if xmlstr.length>0 then
						
						x = XmlSimple.xml_in(xmlstr)

						@list=x['channel'][0]['item']
						
						p "#{Time.now+ (4*60*60)} #{@list.length} items found"
						if @list.length>0 then
							#p "clearing defects from database"
							#@super.remove({"jira_id"=>/#{project['jiraproject']}/})
							p "#{Time.now+ (4*60*60)} adding to mongodb"
							@list.each{|data|
								jira_id=data['key'][0]['content'].gsub(/[^0-9a-z-]+/i,'')
								
								if !@super.find_one({"jira_id"=>"#{jira_id}"}) then
									@super.insert({"jira_id"=> "#{jira_id}"})
								end	
									@super.update({"jira_id" => "#{jira_id}"}, {"$set" => data},  { "upsert"=> true })
							}
						end
					end
				else
					p "#{Time.now+ (4*60*60)} timed out waiting for XML data"
				end	
		end	
		
	}
	
	@b.close if @b
	rescue =>e
	p "#{Time.now+ (4*60*60)} #{e}"
	puts e.cause
	
	ensure
	@b.close if @b
	 @server.stop if @server
	end	


end

def get_superset
begin
	jira_to_mongo
rescue =>e
p "#{Time.now+ (4*60*60)} e"
end
end



