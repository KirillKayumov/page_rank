require "uri"
require "open-uri"
require "open_uri_redirections"
require "nokogiri"
require "pry"
require "benchmark"

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

  private

  def build_matrix
    index = 0
    puts "PARSING..."

    while index < pages.size
      begin
        current_page = pages[index]
        document = Nokogiri::HTML(open(current_page.url, allow_redirections: :all))
        puts "#{index + 1}: #{current_page.url}"

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

        pages.concat(pages_on_current_page).uniq! if pages.size < 100
        current_page.pages = pages_on_current_page
        index += 1
      rescue OpenURI::HTTPError
        pages.delete_at(index)
      end
    end

    pages.each do |current_page|
      current_page.pages &= pages

      edges = current_page.pages.map { |page| [current_page, page] }
      matrix.concat(edges)
    end

    100.times do
      pages.each do |page|
        matrix.each do |edge|
          page.next_rank += edge.first.out_rank if edge.last == page
        end
      end

      pages.each(&:update_rank!)
    end
  end
end
