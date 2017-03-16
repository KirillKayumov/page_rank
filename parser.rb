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

    build_matrix
  end

  def check
    binding.pry unless matrix.transpose.all? { |row| row.reduce(:+).round(3) == 1.0 }
  end

  private

  def build_matrix
    index = 0

    while index < pages.size
      begin
        current_page = pages[index]
        document = Nokogiri::HTML(open(current_page.url, allow_redirections: :all))
        puts "PARSE #{current_page.url}"

        pages_on_current_page = document.css("a").map do |link|
          # next unless link[:href]

          begin
            href = link[:href]&.strip
            url = if href =~ /^\//
              domain + href
            elsif URI.parse(href).host == host
              href
            end
          rescue URI::InvalidURIError
            url = nil
          end

          page = Page.new(url)
          next if !page.valid? || page.url == current_page.url
          page
        end.compact.uniq

        pages.concat(pages_on_current_page).uniq! if pages.size < 100
        current_page.pages = pages_on_current_page
        index += 1
      rescue OpenURI::HTTPError
        pages.delete_at(index)
      end
    end

    pages.each.with_index do |current_page, index|
      pages_count = (pages & current_page.pages).size

      self.matrix[index] = pages.map do |page|
        current_page.pages.include?(page) ? 1.0 / pages_count : 0.0
      end
    end

    self.matrix = matrix.transpose
    # index = 0
    #
    # while keep_building?
    #   document = Nokogiri::HTML(open(url, allow_redirections: :all))
    #   current_page = pages[index]
    #   puts "PARSE #{current_page.url}"
    #
    #   pages_on_current_page = document.css("a").map do |link|
    #     href = link[:href]
    #     next_url = if href =~ /^\//
    #       domain + href
    #     elsif href =~ /^https?\:\/\/#{host}/
    #       href
    #     end
    #
    #     next unless next_url
    #
    #     next_page = Page.new(next_url)
    #     next if next_page.url == url
    #     next_page
    #   end.compact.uniq
    #
    #   pages.concat(pages_on_current_page).uniq! if pages.size < 100
    #
    #   matrix_row = pages.map do |page|
    #     pages_on_current_page.include?(page) ? (1.0 / (pages_on_current_page & pages).size) : 0
    #   end
    #   # binding.pry if url.end_with?("/en")
    #
    #   self.matrix[index] = matrix_row
    #
    #   pages[index].visit!
    #   index += 1
    #   url = pages[index]&.url
    # end
    #
    # matrix.map! do |row|
    #   row + [0] * (pages.size - row.size)
    # end
    # self.matrix = matrix.transpose
  end

  def keep_building?
    return true if pages.empty?

    !pages.all?(&:visited?)
  end
end

# Parser.new.perform
