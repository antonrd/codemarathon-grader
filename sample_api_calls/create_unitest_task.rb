require 'json'
require 'net/http'
require 'uri'

uri = URI('http://localhost:3030/tasks')
access_token = "ca338c89b83f8a153f2f95149ff51e17"
headers = { "Authorization" => "Token token=\"#{access_token}\"" }
req = Net::HTTP::Post.new(uri, headers)

wrapper_code = """
from program import foo

res = foo(14)

print res
"""

args = {
  "email" => 'dimitrov.anton@gmail.com',
  "task[name]" => "new unittest task",
  "task[description]" => "new unittest task description",
  "task[task_type]" => "pyunit",
  "task[wrapper_code]" => wrapper_code
}
req.set_form_data(args)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts JSON::parse(res.body)
