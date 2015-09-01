require 'rubygems'
require 'selenium/server'
include Selenium 
require 'watir-webdriver'
require 'xmlsimple'

@server = Selenium::Server.new('selenium-server-standalone-2.39.0.jar', :background => true)

@server << ["--additional", "-Xms1024m -Xmx1024m"]
@server.start

capabilities = WebDriver::Remote::Capabilities.firefox
#capabilities = WebDriver::Remote::Capabilities.htmlunit(:javascript_enabled => true) 
@b = Watir::Browser.new(:remote, :url => 'http://127.0.0.1:4444/wd/hub', :desired_capabilities => capabilities)
@b.driver.manage.timeouts.implicit_wait = 5000

@b.goto("https://kh07285:TestUser2@collaboration.cmb.citigroup.net/sites/SAECoE/adopt/Lists/by%20app/Default%20View.aspx")
sleep 4
@b.execute_script("window.prompt = function() {return 'my name'}")