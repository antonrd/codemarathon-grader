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

source_code_rb = """
#sleep 3
#loop { fork }
arr = []
1000000000.times do
  arr << rand(1400)
end
puts 'Hello world!'
"""

source_code_cpp = """
//#include <unistd.h>
#include <stdio.h>

int main(void)
{
  char *arr = new char[10000000];
  for (int i = 0; i < 10000000; i++) {
    arr[i] = i * 14;
  }
  int sum = 0;
  for (int i = 0; i < 10000000; i++) {
    sum += arr[i];
  }
  printf(\"%d\\n\", sum);
  return 0;
}
"""

# data_hash = {"source_code" => "", "lang" => "cpp"}
data_hash = {"source_code" => source_code_cpp, "lang" => "cpp"}
# data_hash = {"source_code" => "class program {public static void main(String[] args) { System.out.println(\"Hello world!\"); }}", "lang" => "java"}
# data_hash = {"source_code" => source_code_py, "lang" => "python"}
# data_hash = {"source_code" => source_code_rb, "lang" => "ruby"}
# data_hash = {"source_code" => "print \"Hello\"", "lang" => "python"}

args = {
  "email" => 'dimitrov.anton@gmail.com',
  "run[task_id]" => 1,
  "run[code]" => "run_task",
  "run[data]" => data_hash.to_json,
  "run[max_memory_kb]" => 20000,
  "run[max_time_ms]" => 5000}

req.set_form_data(args)

res = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts JSON::parse(res.body)
