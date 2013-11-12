require 'json'

source_code = "#include <cstdio>" \
  "int main() {" \
    "printf(\"hello world!\n\");" \
    "return 0;" \
  "}" \


run_data = {
  'code' => source_code,
  'lang' => 'c++'
}.to_json

run_data = JSON.generate(run_data, quirks_mode: true)

data = {'email' => 'dimitrov.anton@gmail.com', 
  'run[task_id]' => 2,
  'run[code]' => 'run_task',
  'run[data]' => run_data }.to_json

require 'net/http'
net = Net::HTTP.new("localhost", 3000)
request = Net::HTTP::Post.new("/runs")
request.body = data

response = net.start do |http|
  http.request(request)
end
puts response.code
puts response.read_body