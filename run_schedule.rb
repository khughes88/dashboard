require './superset.rb'
require './subset.rb'
require 'logger'
require 'win32/process'
require 'sys/proctable'
#include Win32
include Sys


def start
#File.delete('scheduler.log') if File.exist?('scheduler.log')
$logger = Logger.new('scheduler.log','hourly')
$logger.level = Logger::WARN
$stdout.reopen("scheduler.log", "w")
$stdout.sync = true
$stderr.reopen($stdout)


	while true
	
	 $stdout.flush
		begin
			
		Sys::ProcTable.ps.each { |ps|
			  if ps.name.downcase == 'firefox.exe'
			    Process.kill('KILL', ps.pid)
			  end
			}

		
  
  

			
			
			
			#£puts "#{Time.now+ (13*60*60)} getting superset"
			get_superset
			#puts "#{Time.now+ (13*60*60)} getting subset"
			get_subset
		rescue Exception=>e
		p e.to_s
		end
		p "#{Time.now+ (4*60*60)} 3 minutes  until next cycle"
		sleep 60
		p "#{Time.now+ (4*60*60)} 2 minutes  until next cycle"
		sleep 60
		p "#{Time.now+ (4*60*60)} 1 minute  until next cycle"
		sleep 60
	end	
	
	
end



start