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
    response.headers["X-GPGAuth-Verify-URL"] = "/home/some_server_verify_URL";
    response.headers["X-GPGAuth-Login-URL"] = "/home/some_login_url";
    response.headers["X-GPGAuth-Logout-URL"] = "/home/some_logout_url";
    # This points to an ACII armored public key (can be multiple keys in one file)
    # that is used to allow the client to import the servers pubic key.
    response.headers["X-GPGAuth-Pubkey-URL"] = ".gnupg/localhost.pub";
    #header('X-GPGAuth-Pubkey-URL: /localhost.pub');

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
