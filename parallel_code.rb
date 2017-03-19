require_relative "parallel_parser"

ROUND_NUMBERS = 3

parser = nil

benchmark = Benchmark.measure do
  parser = ParallelParser.new("https://meduza.io")
  parser.perform!
end

pages = parser.pages

pages.sort_by! { |page| -page.rank }
pages.each do |page|
  puts "#{page.rank.round(ROUND_NUMBERS)}: #{page.url}"
end

puts benchmark
