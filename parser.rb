require "capybara/dsl"
require "capybara-webkit"
require "pry"

require_relative "page"

Capybara.run_server = false
Capybara.current_driver = :webkit

Capybara::Webkit.configure do |config|
  config.allow_unknown_urls
end

class Parser
  include Capybara::DSL

  attr_reader :matrix, :pages

  def initialize
    @matrix = []
    @pages = []
  end

  def perform
    start_page = Page.new("https://meduza.io/")
    pages << start_page

    build_matrix(start_page.url)
    binding.pry
  end

  private

  def build_matrix(url)
    index = 0

    while keep_building?
      begin
        visit url
        current_page = pages[index]
        puts "VISIT #{current_page.url}"

        pages_on_current_page = all("a", visible: true).map do |link|
          href = link[:href]
          url = if href =~ /^\//
            page.current_host + href
          elsif href =~ /^https?\:\/\/meduza.io/
            href
          end

          next unless url

          Page.new(url)
        end.compact.uniq

        pages.concat(pages_on_current_page).uniq! if pages.size < 10

        matrix_row = pages.map { |page| pages_on_current_page.include?(page) ? 1.0 / pages_on_current_page.size : 0 }
        matrix[index] = matrix_row
      rescue Capybara::Webkit::NodeNotAttachedError, Capybara::Webkit::InvalidResponseError
      ensure
        pages[index].visit!
        index += 1
        url = pages[index]&.url
      end
    end
binding.pry
    pages.map!.with_index { |page, index| matrix[index] && page }.compact!
    matrix.compact!
  end

  def keep_building?
    return true if pages.empty?

    !pages.all?(&:visited?)
  end
end

Parser.new.perform
