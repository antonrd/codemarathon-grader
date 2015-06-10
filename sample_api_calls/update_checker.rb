require 'json'
require 'net/http'
require 'uri'

uri = URI('http://localhost:3030/runs')
access_token = "8223fb5a81dd5ca98d267df6907d3cb3"
headers = { "Authorization" => "Token token=\"#{access_token}\"" }
req = Net::HTTP::Post.new(uri, headers)

data_hash = {"source_code" => "int main() { return 0; }", "lang" => "c++"}
# data_hash = {"source_code" => "class program {public static int main(String[] args) {return 0;}}", "lang" => "java"}
# data_hash = {"source_code" => "", "lang" => "python"}

args = {"email" => 'dimitrov.anton@gmail.com', "run[task_id]" => 1, "run[code]" => "update_checker", "run[data]" => data_hash.to_json, "run[max_memory_kb]" => 1000, "run[max_time_ms]" => 1000}
req.set_form_data(args)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts JSON::parse(res.body)
