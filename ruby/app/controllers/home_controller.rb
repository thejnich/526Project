require 'open-uri' # need this or else HTML(open()) will sometimes look in local directories instead of internet

class HomeController < ApplicationController

  def home
    response.headers["X-GPGAuth-Version"] = "1.3.0";
    response.headers["X-GPGAuth-Verify-URL"] = "/server_verify";
    response.headers["X-GPGAuth-Login-URL"] = "/login";
    response.headers["X-GPGAuth-Logout-URL"] = "/logout";
    response.headers["X-GPGAuth-Pubkey-URL"] = "/localkey";
    response.headers["X-GPGAuth-Progress"] = "stage0";
    response.headers["X-GPGAuth-Authenticated"] = "false";
    response.headers["X-GPGAuth-Requested"] = "false";

#    `gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --keyserver keyserver.ubuntu.com --search-keys makha@ucalgary.ca < 1`

    email = 'makha@ucalgary.ca'
    doc = Nokogiri::HTML(open('http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=' + email))
    @text = doc.xpath('//body/pre').first.content.strip
    File.open('temp.key.deleteme', 'w') do |f|
        f.write(@text)
    end
    system('gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --import temp.key.deleteme')
    FileUtils.remove_file('temp.key.deleteme')
    crypto = GPGME::Crypto.new
    encrypted = crypto.encrypt("hey jeff and kyle", :recipients => email)
    @key_response = crypto.decrypt(encrypted)
    @text = "Welcome home, secure users.  Welcome home. Here's the armored public key:" + @text
    @key_response = "And here's the decrypted message:" + @key_response.read
    @test_text = ""
    response.headers.each do |head|
        @test_text += head.to_s + "\n"
    end

#    system('gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --yes --delete-key ' + email) 
  end

  def server_verify
    render :text => "hey there verifia-buddy!"
  end

  def login
    response.headers["X-GPGAuth-Version"] = "1.3.0"
    response.headers["X-GPGAuth-Verify-URL"] = "/server_verify"
    response.headers["X-GPGAuth-Login-URL"] = "/login"
    response.headers["X-GPGAuth-Logout-URL"] = "/logout"
    response.headers["X-GPGAuth-Pubkey-URL"] = "/localkey"
    response.headers["X-GPGAuth-Progress"] = "stage1"
    response.headers["X-GPGAuth-Authenticated"] = "false"
    response.headers["X-GPGAuth-Requested"] = "true"

    email = "makha@ucalgary.ca"
    crypto = GPGME::Crypto.new
    encrypted = crypto.encrypt("ruby nonce here", :recipients => email)
    encrypted_signed = crypto.sign(encrypted.read)
    response.headers["X-GPGAuth-User-Auth-Token"] = encrypted_signed

    render :text => "in the login action method."
  end

  def logout
    render :text => "in the logout action method."
  end

  def localkey
    render :text => "in the localkey url."
  end
end
