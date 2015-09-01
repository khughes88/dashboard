require 'mongo'
include Mongo
require 'selenium/server' 
include Selenium 
require 'watir-webdriver'
require 'xmlsimple'
require './mailer.rb'
require 'open-uri'
require 'net/http'
require './config.rb'
require 'json'


def get_today
return (Time.now + 3600*12).to_date
end	

def hashme(obj)
return JSON.parse(obj.to_a.to_json)     
end

def jiratree

@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@super  = @db['superset']
@projects=hashme(@sub.find())
@projects.each{|p|
mybugs=@super.find({"type.id"=>"1","status.id"=>"6","project.key"=>p['jiraproject']})
bugdays=[]
mybugs.each{|bug|
upd=Date.parse(bug['updated'][0])
cre=Date.parse(bug['created'][0])
diff=upd-cre
bugdays.push(diff.to_i)
}
p bugdays.inject{ |sum, el| sum + el }.to_f / bugdays.size
}	
end	


def reduce_jiras
	
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@super  = @db['superset']
@projects=hashme(@sub.find())
@projects.each{|p|
	p "#{Time.now+ (4*60*60)} collating latest defect data for #{p['projname']}"
	
	
	curr_sp=p['sprint_name']
	
	
	#jiraurl="https://cedt-jira.nam.nsroot.net/jira/issues/?jql="
	#defectsjql="project%20%3D%201655040%20AND%20type%20%3D%20%221%22%20AND%20status%20!%3D%20Closed
	#defectsjql="project='#{p['jiraproject']}%20AND%20type%20%3D%20%221%22%20AND%20status%20!%3D%20Closed"
	jiradefectsurl="https://cedt-jira.nam.nsroot.net/jira/issues/?jql=project%20%3D%20#{p['jiraproject']}%20and%20status!%3DClosed%20and%20type%3D1"
	#jiradefectsurl="#{jiraurl}#{defectsjql}
	#&runQuery=true&clear=true"
	
	
	#tasksjql="project=#{p['jiraproject']} #{fixversion_string} AND type='8' AND status!='Closed'"
	#jiratasksurl="#{jiraurl}#{tasksjql}&runQuery=true&clear=true"
	#reopjql="project=#{p['jiraproject']} AND fixVersion='#{p['jirafixversion']}' AND type='#{"1"}' and status was in('Reopened')"
	#jirareopenedurl="#{jiraurl}#{reopjql}&runQuery=true&clear=true"
	
	
		sev1=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>{"$in"=>["2","1"]},"project.key"=>p['jiraproject']}).count()
		sev2=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"3","project.key"=>p['jiraproject']}).count()
		sev3=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"4","project.key"=>p['jiraproject']}).count()
		sev4=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"5","project.key"=>p['jiraproject']}).count()
		sev1res=@super.find({"type.id"=>"1","status.id"=>"5","priority.id"=>{"$in"=>["2","1"]},"project.key"=>p['jiraproject']}).count()
		sev2res=@super.find({"type.id"=>"1","status.id"=>"5","priority.id"=>"3","project.key"=>p['jiraproject']}).count()
		sev3res=@super.find({"type.id"=>"1","status.id"=>"5","priority.id"=>"4","project.key"=>p['jiraproject']}).count()
		sev4res=@super.find({"type.id"=>"1","status.id"=>"5","priority.id"=>"5","project.key"=>p['jiraproject']}).count()

	
	
	sev1=0 if sev1==nil
	sev2=0 if sev2==nil
	sev3=0 if sev3==nil
	sev4=0 if sev4==nil
	sev1res=0 if sev1res==nil
	sev2res=0 if sev2res==nil
	sev3res=0 if sev3res==nil
	sev4res=0 if sev4res==nil
	
	p "#{Time.now+ (4*60*60)} Sev1: #{sev1} | Sev2: #{sev2} | Sev3: #{sev3} | Sev4: #{sev4}"

		
	
	#defect data attained, add to subset collection
	
	data=Hash.new
	data['jiradefectsurl']=jiradefectsurl

	
	data['projname']=p['projname']
	data['qcid']=p['qcid']
	data['sev1']=sev1
	data['sev2']=sev2
	data['sev3']=sev3
	data['sev4']=sev4

	data['majors']=sev1+sev2
	data['minors']=sev3+sev4

	data['sev1res']=sev1res
	data['sev2res']=sev2res
	data['sev3res']=sev3res
	data['sev4res']=sev4res
	

	if !@sub.find_one({"projname"=>p['projname']}) then
			@sub.insert({"projname"=>p['projname']})
		end	
		@sub.update({"projname"=>p['projname']}, {"$set" => data},  { "upsert"=> true })	
	
	}
end


def get_ci_status
@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@sub  = @db['subset']
@projects=hashme(@sub.find())
@projects.each{|p|
	begin
		puts "#{Time.now+ (4*60*60)} getting CI/TeamCity status for #{p['projname']} "
		buildstatus=ci_get(p['teamcitybuildurl'],p['teamcitybuildid'])
		teststatus=ci_get(p['teamcitytesturl'],p['teamcitytestid'])
		
		data=Hash.new
		data['buildstatus']=buildstatus
		data['teststatus']=teststatus
		data['teamcitybuildurl']=p['teamcitybuildurl']
		data['teamcitytesturl']=p['teamcitytesturl']
		if !@sub.find_one({"projname"=>p['projname']}) then
			@sub.insert({"projname"=>p['projname']})
		end	
		@sub.update({"projname"=>p['projname']}, {"$set" => data},  { "upsert"=> true })	
	rescue Exception => e	
	end
}

end	


def ci_get(url,id)
	puts "#{Time.now+ (4*60*60)} checking TeamCity at #{url} "
	status='unknown'
	begin
		buildtype=id
		
		uri = URI.parse(url)
		response = Net::HTTP.get(uri)
		
		fail_scan=response.scan(/failing.*.\s*.*#{buildtype}"/)
		success_scan=response.scan(/successful.*.\s*.*#{buildtype}"/)
		if fail_scan.length>0 && fail_scan[0].include?(buildtype) then
			
			status='broken'
		elsif success_scan.length>0 && success_scan[0].include?(buildtype) then
			status='ok'
		else
			status='unknown'
		end
	
	rescue Exception => e
		#puts e
			
	end
	p "#{Time.now+ (4*60*60)} Status: #{status}"
	 return status		
		
end	


def monthme(num)
	name=case num
		when 1 then "Jan"
		when 2 then "Feb"
		when 3 then "Mar"
		when 4 then "Apr"
		when 5 then "May"
		when 6 then "Jun"
		when 7 then "Jul"
		when 8 then "Aug"
		when 9 then "Sep"
		when 10 then "Oct"
		when 11 then "Nov"
		when 12 then "Dec"
		else "Jan"
		end
	return name
end

def dayme(num)
	name=case num
		when 0 then "Sun"
		when 1 then "Mon"
		when 2 then "Tue"
		when 3 then "Wed"
		when 4 then "Thu"
		when 5 then "Fri"
		when 6 then "Sat"
		else "Mon"
		end
	return name
end

def numeric?(object)  true if Float(object) rescue false end

def oldest_from_array(myarr)
	
	res=[]
	oldest=nil
	oldid=""
	myarr.each{|d|
	thedate=Date.parse(d['created'][0])
	#p "#{d['jira_id']} #{d['title']}"
	theid=d['jira_id']
	
	if  oldest==nil then 
	oldest=thedate	
	oldid=theid
	else
		if thedate<oldest then
		oldest=thedate
		oldid=theid
		
		end
	end
	}
	
	res[0]=oldest
	res[1]=oldid
	return res
end

def get_oldest
	
       
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['cildata']
	@sub  = @db['subset']
	@projects=hashme(@sub.find())
	@projects.each{|p|
	p "#{Time.now+ (4*60*60)} getting oldest defects for #{p['projname']}"

	

		s1_data=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>{"$in"=>["2","1"]},"project.key"=>p['jiraproject']})
		s2_data=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"3","project.key"=>p['jiraproject']})
		s3_data=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"4","project.key"=>p['jiraproject']})
		s4_data=@super.find({"type.id"=>"1","status.id"=>{"$ne"=>"6"},"priority.id"=>"5","project.key"=>p['jiraproject']})
	today=Date.today
	s1s=hashme(s1_data)
	s2s=hashme(s2_data)
	s3s=hashme(s3_data)
	s4s=hashme(s4_data)
	
	s1oldest_res=oldest_from_array(s1s)
	s2oldest_res=oldest_from_array(s2s)
	s3oldest_res=oldest_from_array(s3s)
	s4oldest_res=oldest_from_array(s4s)
	
	
	
	if s1oldest_res[0]!=nil then s1oldest=(today-s1oldest_res[0]).to_i end
	if s2oldest_res[0]!=nil then s2oldest=(today-s2oldest_res[0]).to_i end
	if s3oldest_res[0]!=nil then s3oldest=(today-s3oldest_res[0]).to_i end
	if s4oldest_res[0]!=nil then s4oldest=(today-s4oldest_res[0]).to_i end 
	
	s1oldest_id=s1oldest_res[1]
	s2oldest_id=s2oldest_res[1]
	s3oldest_id=s3oldest_res[1]
	s4oldest_id=s4oldest_res[1]
	
	s1oldest="n/a" if s1oldest==nil
	s2oldest="n/a" if s2oldest==nil
	s3oldest="n/a" if s3oldest==nil
	s4oldest="n/a" if s4oldest==nil
	
	
	data=Hash.new
		
		data['s1oldest']=s1oldest
		data['s2oldest']=s2oldest
		data['s3oldest']=s3oldest
		data['s4oldest']=s4oldest
		data['s1oldest_id']=s1oldest_id
		data['s2oldest_id']=s2oldest_id
		data['s3oldest_id']=s3oldest_id
		data['s4oldest_id']=s4oldest_id
	
	if !@sub.find_one({"projname"=>p['projname']}) then
		@sub.insert({"projname"=>p['projname']})
	end	
	@sub.update({"projname"=>p['projname']}, {"$set" => data},  { "upsert"=> true })	
			
	
	}

end



def snapshot
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['cildata']
	@sub  = @db['subset']
	@snapshots=@db['snapshots']
	@projects=hashme(@sub.find())
	@projects.each{|p|
	
	time=Time.now+ (4*60*60)
	tidydate=time.strftime('%d/%m/%Y')
	
	if time.hour>7 then
		p "#{Time.now+ (4*60*60)} after 8 am, checking for snapshot"
	if !@snapshots.find_one({"projname"=>p['projname'],"date"=>tidydate}) then
		p "#{Time.now+ (4*60*60)} no snapshot stored for #{p['projname']} on #{tidydate}"
		p "#{Time.now+ (4*60*60)} adding snapshot"
		msg="
QC Update #{tidydate} #{p['projname']}\n
Sev1 defects: #{p['sev1']}
Sev2 defects: #{p['sev2']}
Sev3 defects: #{p['sev3']}
Sev4 defects: #{p['sev4']}
Sprint days remaining: #{p['days_remaining']}\n

http://citiurl/qc_dashboard
		"
		@snapshots.insert({"projname"=>p['projname'],"date"=>tidydate,"msg"=>msg})
		p "#{Time.now+ (4*60*60)} sending mail"
		subj="QC Update #{tidydate} #{p['projname']}"
		mailer(subj,msg)
		
	end	
		

	end
	}
end



def get_jira_chart_data
	
        @today=get_today
	@client = MongoClient.new('localhost', 27017)
	@db     = @client['cildata']
	@sub  = @db['subset']
	@projects=hashme(@sub.find())
	@projects.each{|p|
	p "#{Time.now+ (4*60*60)} rebuilding Jira burndown chart for #{p['projname']}"
 
		daily_closed_totals=[]
		daily_created_totals=[]
		daily_resolved_totals=[]
		hi_unclosed_totals=[]
		low_unclosed_totals=[]
		guide_totals=[]
		project_days=[]
		
		
						
		i=0
		firstbug=@super.find({"type.id"=>"1","project.key"=>p['jiraproject']}).sort({"key.id" => 1}).limit(1).first()
		
		
		if firstbug!=nil then
		
			first_bug_date=Date.parse(firstbug["created"][0])
			sprint_start=Date.parse(p['sprint_start'])
			if first_bug_date<sprint_start then
				start_date=first_bug_date
				
			else
				start_date=sprint_start
			end	
			end_date=Date.parse(p['sprint_end'])
		
			
			hi_unclosed_total=0
			hi_createdon=0
			hi_closedon=0

			low_unclosed_total=0
			low_createdon=0
			low_closedon=0
			
			today_in_jira_format="#{dayme(@today.wday)}, #{@today.day} #{monthme(@today.month)} #{@today.year}"
			date_in_question=start_date
			
			until date_in_question==end_date+1 do
				date_in_question=start_date+(i)
					
				jira_formatted_date="#{dayme(date_in_question.wday)}, #{date_in_question.day} #{monthme(date_in_question.month)} #{date_in_question.year}"
				
				#for another chart
				
				createdon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"created"=>/#{jira_formatted_date}/}).count()
				closedon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"status.id"=>"6","updated"=>/#{jira_formatted_date}/}).count()
				resolvedon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"resolved"=>/#{jira_formatted_date}/}).count()
					
				
					hi_createdon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"priority.id"=>{"$in"=>["1","2","3"]},"created"=>/#{jira_formatted_date}/}).count()
					hi_closedon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"priority.id"=>{"$in"=>["1","2","3"]},"status.id"=>"6","updated"=>/#{jira_formatted_date}/}).count()
					
					low_createdon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"priority.id"=>{"$in"=>["4","5"]},"created"=>/#{jira_formatted_date}/}).count()
					low_closedon=@super.find({"type.id"=>"1","project.key"=>p['jiraproject'],"priority.id"=>{"$in"=>["4","5"]},"status.id"=>"6","updated"=>/#{jira_formatted_date}/}).count()
					
				hi_unclosed_total+=hi_createdon-hi_closedon
				low_unclosed_total+=low_createdon-low_closedon
				
				if date_in_question<=end_date && date_in_question>=sprint_start then

					
					
					
					if date_in_question<=@today
						hi_unclosed_totals.push(hi_unclosed_total)
						low_unclosed_totals.push(low_unclosed_total)
						daily_closed_totals.push(closedon)
						daily_resolved_totals.push(resolvedon)
						daily_created_totals.push(createdon)
					else
						
						hi_unclosed_totals.push(nil)
						low_unclosed_totals.push(nil)
						daily_closed_totals.push(nil)
						daily_resolved_totals.push(nil)
						daily_created_totals.push(nil)
										
					end
					
					db_formatted_date=Time.parse(date_in_question.to_s).to_i*1000
					project_days.push(db_formatted_date)
					guide_totals.push(10)
					
				end
				i+=1
			end	
			
			
			
		end
		
		

		data=Hash.new
		if hi_unclosed_totals.size<1 then hi_unclosed_totals=[0] end
		if low_unclosed_totals.size<1 then low_unclosed_totals=[0] end
		#p hi_unclosed_totals
		data['daily_closed_totals']=daily_closed_totals
		data['daily_resolved_totals']=daily_resolved_totals
		data['daily_created_totals']=daily_created_totals
		data['hi_jiracurve']=hi_unclosed_totals
		data['low_jiracurve']=low_unclosed_totals
		data['jiracurve_guide']=guide_totals
		data['project_days']=project_days
	
		today=(Time.now + 3600*12).to_date
	
		
		rem=(Date.parse(p['sprint_end'])-today).to_i
		rem=0 if rem<1
		data['days_remaining']=rem
	
	if !@sub.find_one({"projname"=>p['projname']}) then
		@sub.insert({"projname"=>p['projname']})
	end	
	@sub.update({"projname"=>p['projname']}, {"$set" => data},  { "upsert"=> true })	
			
	
	}

end



def mean(x)
  sum=0
  x.each {|v| sum += v}
  if x.size>0 then
  mean=sum/x.size
  else
 mean=0
 end
end

def variance(x)
  m = mean(x)
  sum =0.0
  x.each {|v| sum += (v-m)**2 }
  sum/x.size
end

def get_days_remaining
@today=get_today
@projects=JSON.load(File.read('config.json').gsub("\n",""))['projects']
@projects.each{|p|
end_date=Date.parse(p["end_date"])
rem=(end_date-@today).to_i
data=Hash.new
	data['days_remaining']=rem
	if !@sub.find_one({"projname"=>p['projname']}) then
		@sub.insert({"projname"=>p['projname']})
	end	
	@sub.update({"projname"=>p['projname']}, {"$set" => data},  { "upsert"=> true })	
	
}
end

def get_subset
	begin snapshot
	rescue Exception => e 
	end
	begin reduce_jiras 
	rescue Exception => e 
	end
	begin get_ci_status 
	rescue Exception => e 
	end
	begin get_jira_chart_data 
	rescue Exception => e 
	end
	begin get_oldest
	rescue Exception => e 
	end

end


