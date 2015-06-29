require 'json'
require 'net/http'
require 'uri'

uri = URI('http://localhost:3030/runs')
access_token = "ca338c89b83f8a153f2f95149ff51e17"
headers = { "Authorization" => "Token token=\"#{access_token}\"" }
req = Net::HTTP::Post.new(uri, headers)

source_code_py = """
def foo(value):
  return value + 10
"""

# data_hash = {"source_code" => "", "lang" => "cpp"}
# data_hash = {"source_code" => "#include <cstdio> int main() { printf(\"Hello world!\"); return 0; }", "lang" => "cpp"}
# data_hash = {"source_code" => "class program {public static void main(String[] args) { System.out.println(\"Hello world!\"); }}", "lang" => "java"}
data_hash = {"source_code" => source_code_py, "lang" => "python"}
# data_hash = {"source_code" => "puts \"Hello world!\"", "lang" => "ruby"}

args = {"email" => 'dimitrov.anton@gmail.com', "run[task_id]" => 3, "run[code]" => "run_task", "run[data]" => data_hash.to_json, "run[max_memory_kb]" => 10000000, "run[max_time_ms]" => 1000}
req.set_form_data(args)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts JSON::parse(res.body)
