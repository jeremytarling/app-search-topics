require 'restclient'
require 'json'

# LDP URL
API_KEY = ""

SSL = {
  :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read("/etc/pki/tls/certs/client.crt")),
  :ssl_client_key => OpenSSL::PKey::RSA.new(File.read("/etc/pki/tls/private/client.key")),
  # need this next line for self-signed BBC cloud CA:
  :ssl_ca_file => "/etc/pki/tls/certs/CloudServicesRoot.pem"
}

# GET some data for each GUID
def getDataFromLDP(guid)

  url = "https://ldp-core.api.bbci.co.uk/ldp-core/things/" + guid.strip + "?api_key=" + API_KEY

  begin
    ldp_response = RestClient::Resource.new(url, SSL).get({:accept => "application/json-ld"}) 
    ldp_response_json = JSON.parse ldp_response.body  
    id = ldp_response_json['@id'][28..63]

    # some records have more than one perferred label :-(
    if ldp_response_json['preferredLabel'].kind_of?(Array)
      name = ldp_response_json['preferredLabel'][0]
    else
      name = ldp_response_json['preferredLabel']
    end
    
    #some disambiguationHints are empty
    if ldp_response_json['disambiguationHint'].nil?
      dis = ""
    else
      dis = ldp_response_json['disambiguationHint']
    end

    # some alt labels are empty, and the App team like them all to be arrays (even if they're just strings)
    if ldp_response_json['skos:altLabel'].nil?
      alt = []
    else
      if ldp_response_json['skos:altLabel'].kind_of?(Array)
        alt = ldp_response_json['skos:altLabel']
      else
        alt = "[\"" + ldp_response_json['skos:altLabel'] + "\"]"
      end
    end

    # build up a hash of the data we need for this guid
    @row = %Q!{"id" : "/ldp/#{id}", "name" : "#{name}", "dis" : "#{dis}", "alt" : #{alt}}! 

  rescue => @error
    puts "error for #{guid.strip}: #{@error}"
  end

end

# grab the input from ARGV[0]
guids=File.open(ARGV[0]).read

# opening bracket
File.open("newsapp_topics.json", 'w') { |file| file.write("[") }

# fetch data and write out to newsapp_topics.json
guids.each_line do |guid|
  
  getDataFromLDP(guid)

  # append it as a new row to the JSON doc
  File.open("newsapp_topics.json","a") do |topic|
    topic.write(@row + ",\n")
    puts "wrote #{guid.strip} to file succesfully"
  end
end

# closing bracket
File.open("newsapp_topics.json", 'a') { |file| file.write("]") }



