require 'net/http'

class HomeController < ApplicationController

  def home
    @text = "Welcome home, secure users.  Welcome home."
    url = URI.parse('http://keyserver.ubuntu.com:11371/pks/lookup')
    http = Net::HTTP.new(url.host, url.port)
    params = { 'op' => 'get', 'search' => 'makha@ucalgary.ca' }
    req = Net::HTTP::Get.new(url.path)
    req.set_form_data(params)
    req = Net::HTTP::Get.new(url.path + '?' + req.body)

    res = http.request(req)
    @text = @text

    @key_response = res.body
  end
end
