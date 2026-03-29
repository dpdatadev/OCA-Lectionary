# frozen_string_literal: true

require 'nokogiri'
require 'httparty'
require 'logger'

module Bible 
  class Reading 
    attr_reader :book, :chapter, :verses

    def initialize(book, chapter, verses)
      @book = book
      @chapter = chapter
      @verses = verses
    end

    def to_s
      "#{@book} #{@chapter}:#{@verses}"
    end
  end
end

module Scrapers
  class ServiceUtils 
    class << self
      def debug_log(message)
        logger = Logger.new($stdout)
        logger.info(message)
      end
      def post_to_markdown_service(url_to_convert_to_markdown)
        HTTParty.post('http://127.0.0.1:7171/md?url=' + url_to_convert_to_markdown)
        debug_log("Saved contents to MARKDOWN")
      end
    end
  end
  # https://www.delftstack.com/howto/ruby/ruby-nil-empty-blank/
  # 
  #MONKEY MADNESS
  class Object
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end

  class String 
    def substring(word1, word2)
      self.partition(word1).last.rpartition(word2).first.strip
    end
  end

  LinkElement = Data.define(:link, :text) do
    include Comparable

    def to_s
      "\n::Element Link::#{link}::Element Text::#{text}::\n"
    end

    # we want to be able to sort an array of elements based on link
    def <=>(other)
      # sort/order by the link
      self.link <=> other.link
    end
  end

  class ScriptureReading < LinkElement
    def to_s
      "\n::Daily Orthodox Scripture Reading (OCA.org)::#{link}::Scripture Text::#{text}::\n"
    end
  end

  class OCALectionary
    attr_reader :daily_reading_links, :daily_reading_count

    URL = 'https://www.oca.org/readings/daily'
    DEBUG = true

    def initialize(url = URL, debug = DEBUG)
      @url = url
      @debug_is_enabled = debug
      @daily_reading_links = []
      @daily_reading_count = 0
    end

    def load_readings
      scrape_page = self.download_page
      doc = self.parse_page(scrape_page)
      links = self.extract_links(doc)
      self.create_reading_objects(links)
    end

    def verse_list
      verses = []
      if @daily_reading_count > 0
        @daily_reading_links.each do |reading|
          verses.push(reading.text)
        end
        verses
      else
        puts "No readings to load verses for."
      end
    end

    def download_page
      HTTParty.get(@url).body
    end

    def parse_page(page_body)
      Nokogiri::HTML(page_body)
    end

    def extract_links(doc)
      doc.search('#main #content section ul li a')
    end

    def create_reading_objects(links)
      links.map do |link|
        s = ScriptureReading.new(link['href'].prepend('https://www.oca.org'), link.text.strip)
        pp s.to_s if @debug_is_enabled
        @daily_reading_links.push(s)
        @daily_reading_count += 1
      end
    end

    def get_page_info()
        scrape_page = self.download_page
        doc = self.parse_page(scrape_page)

        # find all links
        #links = doc.search('a')

        # see how many we're working with
        #puts "There are #{links.size} links found"

        # title of the document
        puts doc.title
    end

    def log_child_page(reading_link, output_file)
      reading_raw = HTTParty.get(reading_link).body
      reading_doc = Nokogiri::HTML(reading_raw)
      reading_title = reading_doc.search('#main #content section article h2')
      reading_text = reading_doc.search('#main #content section article dl dd')

      title = reading_title.text.strip
      text = reading_text.text.strip

      File.open(output_file, 'w') do |file|
        file << title
        file << "\n"
        file << text
      end
      if @debug_is_enabled == 1
        pp title
        pp text
      end
    end
    def get_bulk_monthly_readings(year, month)
      readings = []
      request = HTTParty.get("http://127.0.0.1:7171/table?url=https://www.oca.org/readings/monthly/#{year}/#{month}")
      readings = request.parsed_response["TableText"].split("\n").map(&:strip).reject(&:empty?)
      readings.each do |reading|
        puts reading
        # parse the book and verse chapters from the string
        # example string: "Acts 2:1-11"
        if reading =~ /(\w+)\s+(\d+:\d+-\d+)/
          book = $1
          #at first the 'verses' also contains the book, we'll strip that out
          verses = $2
          chapter = verses.split(':').first
          #now reassign verses from the initial variable with the chapter part removed
          verses = verses.split(':').last
          b = Bible::Reading.new(book, chapter, verses)
          readings.push(b)
          puts "Book: #{b.book},  Chapter: #{b.chapter}, Verses: #{b.verses}"
        end
      end
    end
  end
end



# notes:
# todo, handle "skipped verses", multiple separate verse readings from the same book and chapter, e.g. "Matthew 10:32-33, 37-38"
# create a 'local' option that allows us to extract the neccessary verses from the daily lectionary and look up those verses in our KJV sqlite database
# or we can also query a monthly lectionary that has been saved and reference from the database (todo, more on this later)