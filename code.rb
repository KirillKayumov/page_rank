require_relative "parser"

ROUND_NUMBERS = 3

parser = Parser.new("https://meduza.io")
parser.perform!

pages = parser.pages

pages.sort_by! { |page| -page.rank }
pages.each.with_index do |page, index|
  puts "#{page.rank.round(ROUND_NUMBERS)}: #{page.url}"
end
