require "celluloid"

require_relative "parser"

class ParallelParser < Parser
  private

  def parse_pages(index, current_page)
    begin
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

      current_page.pages = pages_on_current_page
      pages_on_current_page
    rescue OpenURI::HTTPError
      nil
    end
  end

  def build_edges(current_page, pages)
    current_page.pages &= pages
    current_page.pages.map { |page| [current_page, page] }
  end

  def build_matrix
    index = 0
    puts "PARSING..."

    while index < pages.size
      range = (index...pages.size).to_a
      futures = range.map do |index|
        Celluloid::Future.new { parse_pages(index, pages[index]) }
      end

      futures.each.with_index do |future, index|
        pages[range[index]] = nil if future.value.nil?
      end

      pages.compact!
      index = pages.size

      futures.each do |future|
        pages.concat(future.value).uniq! if !future.value.nil? && pages.size < 100
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
