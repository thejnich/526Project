require 'open-uri' # need this or else HTML(open()) will sometimes look in local directories instead of internet

class HomeController < ApplicationController

  def home
    response.headers["X-GPGAuth-Version"] = "1.3.0";
    response.headers["X-GPGAuth-Requested"] = "false";
    # The following headers describe to the client where to look for resources;
    # The way this example PHP page actually operates, the '?page' are just for 
    # differentiating the requests while debugging/testing - the only page that requires
    # a "?page" querystring variable in this example is the logout page.
    # All of these paths must be relative to the root of the domain. Nothing else will
    # be permitted by the client.
    response.headers["X-GPGAuth-Verify-URL"] = "/server_verify";
    response.headers["X-GPGAuth-Login-URL"] = "/login";
    response.headers["X-GPGAuth-Logout-URL"] = "/logout";
    # This points to an ACII armored public key (can be multiple keys in one file)
    # that is used to allow the client to import the servers pubic key.
    response.headers["X-GPGAuth-Pubkey-URL"] = ".gnupg/localhost.pub";
    #header('X-GPGAuth-Pubkey-URL: /localhost.pub');

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

#    system('gpg --homedir /home/masudio/development/cpsc526/526Project/ruby/.gnupg --yes --delete-key ' + email) 
  end

  def server_verify
    render :text => "hey there verifia-buddy!"
  end

  def login
    render :text => "in the login action method."
  end

  def logout
    render :text => "in the logout action method."
  end
end
