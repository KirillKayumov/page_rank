# require "capybara/dsl"
# require "capybara-webkit"
require "open-uri"
require "nokogiri"
require "pry"

require_relative "page"

# Capybara.run_server = false
# Capybara.current_driver = :webkit
#
# Capybara::Webkit.configure do |config|
#   config.allow_unknown_urls
# end

class Parser
  # include Capybara::DSL
  HOST = "https://meduza.io"

  attr_accessor :matrix, :pages
  attr_accessor :pages

  def initialize
    @matrix = []
    @pages = []
  end

  def perform
    start_page = Page.new(HOST)
    pages << start_page

    build_matrix(start_page.url)
    binding.pry
  end

  private

  def build_matrix(url)
    index = 0

    while keep_building?
      document = Nokogiri::HTML(open(url))
      current_page = pages[index]
      puts "PARSE #{current_page.url}"

      pages_on_current_page = document.css("a").map do |link|
        href = link[:href]
        url = if href =~ /^\//
          HOST + href
        elsif href =~ /^https?\:\/\/meduza.io/
          href
        end

        next unless url

        Page.new(url)
      end.compact.uniq

      pages.concat(pages_on_current_page).uniq! if pages.size < 100

      matrix_row = pages.map do |page|
        pages_on_current_page.include?(page) ? (1.0 / pages_on_current_page.size).round(2) : 0
      end
      self.matrix[index] = matrix_row

      pages[index].visit!
      index += 1
      url = pages[index]&.url
    end

    matrix.map! do |row|
      row + [0] * (pages.size - row.size)
    end
    self.matrix = matrix.transpose
  end

  def keep_building?
    return true if pages.empty?

    !pages.all?(&:visited?)
  end
end

Parser.new.perform
