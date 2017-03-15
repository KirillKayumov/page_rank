class Page
  attr_reader :url
  attr_accessor :visited

  def initialize(url)
    @url = url.gsub(/\?.*/, "").chomp("/")
    @visited = false
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
