require 'date'
require 'net/smtp'

def mailer(subj,msg)

#recips=['keith.hughes@citi.com']
  recips=['khughes88@gmail.com']

recips.each{|recip|
message = <<MESSAGE_END
From: QC Dashboard <do not reply>
To: <#{recip}>
Subject: #{subj}
#{msg}
MESSAGE_END

Net::SMTP.start('mailhub-vip.ny.ssmb.com') do |smtp|
  smtp.send_message message, recip, recip
end

}

end


