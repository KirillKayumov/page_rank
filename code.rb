require_relative "parser"

ROUND_NUMBERS = 3

parser = Parser.new("https://meduza.io")
parser.perform!
parser.check

matrix = parser.matrix
pages = parser.pages

# File.open('matrix.txt', 'w') do |file|
#   matrix.each do |row|
#     file.write(row)
#     file.write("\n")
#   end
# end
# binding.pry


# matrix = [
#   [0, 0, 1, 1.0 / 2],
#   [1.0 / 3, 0, 0, 0],
#   [1.0 / 3, 1.0 / 2, 0, 1.0 / 2],
#   [1.0 / 3, 1.0 / 2, 0, 0]
# ]
ranks = [0.85] * matrix.size

loop do
  next_ranks = ranks.map.with_index do |rank, index|
    matrix[index].map.with_index { |elem, index| elem * ranks[index] }.reduce(:+)
  end

  break if ranks.map { |elem| elem.round(ROUND_NUMBERS) } == next_ranks.map { |elem| elem.round(ROUND_NUMBERS) }
  ranks = next_ranks
end

ranks.sort.reverse.each.with_index do |rank, index|
  puts "#{rank.round(ROUND_NUMBERS)}: #{pages[index].url}"
end
