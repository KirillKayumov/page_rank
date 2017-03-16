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

        pages.concat(pages_on_current_page).uniq! if pages.size < 10
        current_page.pages = pages_on_current_page
        index += 1
      rescue OpenURI::HTTPError
        pages.delete_at(index)
      end
    end

    # self.pages = [
    #   Page.new("A"),
    #   Page.new("B"),
    #   Page.new("C"),
    #   Page.new("D"),
    # ]
    # pages[0].pages = [pages[1], pages[2]]
    # pages[1].pages = [pages[2]]
    # pages[2].pages = [pages[0]]
    # pages[3].pages = [pages[2]]

    pages.each.with_index do |current_page, index|
      current_page.pages = pages & current_page.pages

      self.matrix[index] = pages.map do |page|
        current_page.pages.include?(page) ? 1 : 0
      end
    end

    self.matrix = matrix.transpose

    5.times do
      pages.each.with_index do |page, current_index|
        matrix[current_index].each.with_index do |elem, index|
          pages[current_index].next_rank += pages[index].out_rank if elem == 1
        end
      end

      pages.each(&:update_rank!)
    end

    # pages.each.with_index do |current_page, index|
    #   pages_count = (pages & current_page.pages).size
    #
    #   self.matrix[index] = pages.map do |page|
    #     current_page.pages.include?(page) ? 1.0 / pages_count : 0.0
    #   end
    # end
    #
    # self.matrix = matrix.transpose
    # index = 0
  end

  def keep_building?
    return true if pages.empty?

    !pages.all?(&:visited?)
  end
end

# Parser.new.perform
