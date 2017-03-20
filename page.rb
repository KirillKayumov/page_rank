class Page
  attr_reader :url # создаём геттер
  attr_accessor :visited, :pages, :rank, :next_rank # создаёт геттер и сеттер

  FADING = 0.85

  def initialize(url)
    return unless url

    @url = url.gsub(/\?.*/, "").gsub(/\#.*/, "").chomp("/") # gsub – земенает в строке первое на второе, chomp – убрать символ с конца
    @visited = false
    @pages = []
    @rank = 1 - FADING
    @next_rank = @rank
  end

  def out_rank
    rank * FADING / pages.size
  end

  def update_rank!
    self.rank = next_rank
    self.next_rank = 1 - FADING
  end

  def valid?
    !url.nil?
  end

  def visited?
    visited
  end

  def visit!
    self.visited = true
  end

  def ==(another_page)
    eql?(another_page)
  end

  def eql?(another_page)
    url == another_page.url
  end

  def hash
    url.size
  end
end
