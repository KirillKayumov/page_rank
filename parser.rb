require "uri"
require "open-uri"
require "open_uri_redirections"
require "nokogiri" # парсить HTML страницы
require "benchmark" # замерять время выполнения кода

require_relative "page"

class Parser
  attr_accessor :matrix, :pages, :domain, :host

  def initialize(domain)
    @domain = domain # https://meduza.io
    @host = URI.parse(domain).host # meduza
    @matrix = [] # список рёбер
    @pages = [] # cписок всех страниц (вершин графа)
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

    # begin ... rescure
    # try ... catch
    while index < pages.size
      begin
        current_page = pages[index]
        document = Nokogiri::HTML(open(current_page.url, allow_redirections: :all))
        puts "#{index + 1}: #{current_page.url}"

        pages_on_current_page = document.css("a").map do |link| # link – Nokogiri-шный объект с аттрибутами (href)
          begin
            # href:
            # 1. /news
            # 2. http://lenta.ru/news
            # 3. nil
            href = link[:href]&.strip # :lol – символ lol, strip – удаление пробелов в конце и в начале, &. – позволяет вызвать метод на nil
            url = if href =~ /^\// # =~ – проверка строки на регулярку
              domain + href
            elsif URI.parse(href).host == host
              href
            end
          rescue URI::InvalidURIError
            url = nil
          end

          page = Page.new(url)
          next if !page.valid? || page.url == current_page.url # next – выйти из блока
          page
        end.compact.uniq # compact – удаляет всё nil из массива, uniq – оставляет только уникальные pages

        pages.concat(pages_on_current_page).uniq! if pages.size < 100 # присоединяет массив к массиву
        current_page.pages = pages_on_current_page
        index += 1
      rescue OpenURI::HTTPError
        pages.delete_at(index)
      end
    end

    pages.each do |current_page|
      current_page.pages &= pages # &= – пересечение массивов, a &= b : a = a & b

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
