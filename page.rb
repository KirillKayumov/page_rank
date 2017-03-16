class Page
  attr_reader :url
  attr_accessor :visited, :pages, :rank, :next_rank

  FADING = 0.85

  def initialize(url)
    return unless url

    @url = url.gsub(/\?.*/, "").chomp("/")
    @visited = false
    @pages = []
    @rank = 1
    @next_rank = 1
  end

  def out_rank
    rank * FADING / pages.size
  end

  def update_rank!
    self.rank = next_rank
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
