class Page
  attr_reader :url
  attr_accessor :visited, :pages

  def initialize(url)
    return unless url

    @url = url.gsub(/\?.*/, "").chomp("/")
    @visited = false
    @pages = []
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
