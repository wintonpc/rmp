require 'net/smtp'
require 'securerandom'

class Sendmail
  class << self
    def send_mail(file_path, recipient_address)

      sender_address = 'mermer541@gmail.com'

      # taken from http://www.tutorialspoint.com/ruby/ruby_sending_email.htm

      filecontent = File.read(file_path)
      encodedcontent = [filecontent].pack('m')   # base64
      filename = File.basename(file_path)

      marker = SecureRandom.hex(12)

      body =<<EOF
#{filename}
EOF

# Define the main headers.
      part1 =<<EOF
From: Ruby Memory Profiler <#{sender_address}>
To: RMP User <#{recipient_address}>
Subject: Ruby Memory Profiler: #{filename}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

# Define the message action
      part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF

# Define the attachment section
      part3 =<<EOF
Content-Type: multipart/mixed; name=\"#{filename}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{filename}"

#{encodedcontent}
--#{marker}--
EOF

      mailtext = part1 + part2 + part3

      begin
        Net::SMTP.new('smtp.gmail.com', 456).start('nowhere.net', 'mermer541@gmail.com', 'rmp4ever', :plain) do |smtp|
          smtp.sendmail(mailtext, sender_address, [recipient_address])
        end
      rescue Exception => e
        puts "Exception occurred: #{e}"
      end
    end
  end
end

recipient_address, file_path = ARGV
Sendmail.send_mail(file_path, recipient_address)
