require 'date'
require 'net/smtp'

def mailer(subj,msg)

recips=['khughes88@gmail.com','keith.hughes@citi.com']
#recips=['keith.hughes@citi.com','paud.okeeffe@citi.com']

recips.each{|recip|
message = <<MESSAGE_END
From: CIL QC Dashboard <do not reply>
To: <#{recip}>
Subject: #{subj}
#{msg}
MESSAGE_END

Net::SMTP.start('mailhub-vip.ny.ssmb.com') do |smtp|
  smtp.send_message message, recip, recip
end
	
}

end


mailer("hey","test")