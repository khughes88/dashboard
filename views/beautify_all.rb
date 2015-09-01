Dir.glob(File.join(File.dirname(__FILE__), './*.json')).each do |testfile|  
system("ruby beautify.rb #{File.basename(testfile)}")
end 