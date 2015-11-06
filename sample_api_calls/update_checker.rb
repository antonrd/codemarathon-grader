require 'json'
require 'net/http'
require 'uri'

uri = URI('http://grader.codemarathon.com/runs')
access_token = "5f4fb3962c7b99132afb42d45ffa6575"
headers = { "Authorization" => "Token token=\"#{access_token}\"" }
req = Net::HTTP::Post.new(uri, headers)

data_hash = {"source_code" => "#!/usr/bin/python2.7", "lang" => "python"}
# data_hash = {"source_code" => "class program {public static int main(String[] args) {return 0;}}", "lang" => "java"}
# data_hash = {"source_code" => "", "lang" => "python"}

args = {"email" => 'dimitrov.anton@gmail.com', "run[task_id]" => 1, "run[code]" => "update_checker", "run[data]" => data_hash.to_json}
req.set_form_data(args)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts JSON::parse(res.body)
