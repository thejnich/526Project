#require 'net/http'

class HomeController < ApplicationController

  def home
#    `gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --keyserver keyserver.ubuntu.com --search-keys makha@ucalgary.ca < 1`

    doc = Nokogiri::HTML(open('http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=makha@ucalgary.ca'))
    @text = doc.xpath('//body/pre').first.content.strip
    File.open('temp.key.deleteme', 'w') do |f|
        f.write(@text)
    end
    system('gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --import temp.key.deleteme')
    FileUtils.remove_file('temp.key.deleteme')
    @key_response = OpenPGP::Message.parse(OpenPGP.dearmor(@text.to_s))
    @text = "Welcome home, secure users.  Welcome home. Here's the armored public key:" + @text
    @key_response = "And here's the de-armored message:" + @key_response.to_s
  end
end
