require "uri"
require "open-uri"
require 'open_uri_redirections'
require "nokogiri"
require "pry"

require_relative "page"

class Parser
  attr_accessor :matrix, :pages, :domain, :host

  def initialize(domain)
    @domain = domain
    @host = URI.parse(domain).host
    @matrix = []
    @pages = []
  end

  def perform!
    start_page = Page.new(domain)
    pages << start_page

    build_matrix(start_page.url)
  end

  def check
    binding.pry unless matrix.transpose.all? { |row| row.reduce(:+).round(3) == 1.0 }
  end

  private

  def build_matrix(url)
    index = 0

    while keep_building?
      document = Nokogiri::HTML(open(url, allow_redirections: :all))
      current_page = pages[index]
      puts "PARSE #{current_page.url}"

      pages_on_current_page = document.css("a").map do |link|
        href = link[:href]
        next_url = if href =~ /^\//
          domain + href
        elsif href =~ /^https?\:\/\/#{host}/
          href
        end

        next unless next_url

        next_page = Page.new(next_url)
        next if next_page.url == url
        next_page
      end.compact.uniq

      pages.concat(pages_on_current_page).uniq! if pages.size < 100

      matrix_row = pages.map do |page|
        pages_on_current_page.include?(page) ? (1.0 / (pages_on_current_page & pages).size) : 0
      end
      # binding.pry if url.end_with?("/en")

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

# Parser.new.perform
