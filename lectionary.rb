# frozen_string_literal: true

# version, 0.0.1 ALPHA

require 'nokogiri'
require 'httparty'
require 'logger'

require_relative 'repo'

 # https://www.delftstack.com/howto/ruby/ruby-nil-empty-blank/
  #
  # MONKEY MADNESS
  class Object
    def blank?
      respond_to?(:empty?) ? empty? : !self
    end
  end

  class String
    def substring(word1, word2)
      partition(word1).last.rpartition(word2).first.strip
    end
  end

module Bible
  class Reference
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

  class Reading
    attr_reader :reference, :text

    def initialize(reference, text)
      @reference = reference
      @text = text
    end

    def to_s
      "\n#{@reference}
      \n#{@text}"
    end
  end
end

module Scrapers
  class ServiceUtils
    class << self
      def debug_log(message)
        logger = Logger.new($stdout)
        logger.debug(message)
      end

      def post_to_markdown_service(url_to_convert_to_markdown)
        HTTParty.post("http://127.0.0.1:7171/md?url=#{url_to_convert_to_markdown}")
        debug_log('Saved contents to MARKDOWN')
      end
    end
  end

  class Today 
    class << self
      def year
        Time.now.year
      end
      def month
        Time.now.month
      end
      def day
        Time.now.day
      end
      def days_from(days)
        (Time.now + (days * 24 * 60 * 60))
      end
      def to_s
        Time.now.strftime("%Y-%m-%d")
      end
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
      link <=> other.link
    end
  end

  class ScriptureLink < LinkElement
    def to_s
      "\n::Daily Orthodox Scripture Reading (OCA.org)::#{link}::Scripture Text::#{text}::\n"
    end
  end

  class OCALectionary
    attr_reader :url, :daily_reading_links, :daily_reading_count
    attr_writer :dump_daily_readings, :debug_is_enabled

    # hardcoded for testing
    URL = 'https://www.oca.org/readings/daily'
    DEBUG = true 

    SCRAPE_SERVE_API = "http://127.0.0.1:7171"
    VERSE_SERVE_API = "http://127.0.0.1:7777"

    def initialize(url = URL, debug = DEBUG)
      @url = url
      @debug_is_enabled = debug
      @daily_reading_links = []
      @daily_reading_count = 0
      website_is_reachable?
    end

    def load_readings
      # 4. Create reading/reference objects from the extracted links
      create_reading_objects(
        # 3. Use CSS Selectors to find the needed links
        extract_links(
          # 2. Load the document with Nokogiri
          parse_page(
            # 1. Download the page with HTTParty
            self.download_page(@url) # Ew, looks like Python code :D
          )
        )
      )
      return unless @dump_daily_readings == true

      Scrapers::ServiceUtils.debug_log("Dumping daily readings to disk:\n")
      @daily_reading_links.each do |reading|
        link = reading.link
        reading_file = "./readings/#{reading.text.gsub(/\s+/, '_')}.txt"
        Scrapers::ServiceUtils.debug_log("Downloading reading from #{link} to #{reading_file}") if @debug_is_enabled
        self.download_single_reading_page(link, reading_file)
      end
    end

    def verse_list
      verses = []
      if @daily_reading_count.positive?
        @daily_reading_links.each do |reading|
          verses.push(reading.text)
        end
        verses
      else
        puts 'No readings to load verses for.' # rescue, log fatal
      end
      verses
    end

    def download_page(url = @url)
      HTTParty.get(url).body
    end

    def parse_page(page_body)
      Nokogiri::HTML(page_body)
    end

    def extract_links(doc)
      doc.search('#main #content section ul li a')
    end

    def create_reading_objects(links)
      links.map do |link|
        s = Scrapers::ScriptureLink.new(link['href'].prepend('https://www.oca.org'), link.text.strip)
        pp s.to_s if @debug_is_enabled
        @daily_reading_links.push(s)
        @daily_reading_count += 1
      end
    end

    def get_page_info
      scrape_page = download_page
      doc = parse_page(scrape_page)
      puts doc.title
    end

    def show_troparia(timeframe=Scrapers::Today)
      doc = parse_page(download_page(url="https://www.oca.org/saints/troparia/#{timeframe.year}/#{timeframe.month}/#{timeframe.day}/"))
      troparia = doc.search('article')
      puts "Troparia:\n#{troparia.text.strip}"
      if @dump_daily_readings == true
        Scrapers::ServiceUtils.debug_log("Dumping troparia to disk:\n")
        File.open("./readings/troparia_#{timeframe.to_s}.txt", 'w+') do |file|
          file << "Troparia for #{timeframe.to_s}:\n\n"
          file << troparia.text.strip
        end
      end
    end

    def download_single_reading_page(reading_link, output_file)
      reading_doc = parse_page(download_page(reading_link))
      reading_title = reading_doc.search('#main #content section article h2')
      reading_text = reading_doc.search('#main #content section article dl dd')

      title = reading_title.text.strip
      text = reading_text.text.strip

      reading = Bible::Reading.new(title, text)

      File.open(output_file, 'w') do |file|
        file << reading.to_s
      end

      pp reading if @debug_is_enabled
    end

    def display_referenced_readings(readings)
      readings.each do |reading|
        puts "Reading Reference: #{reading.reference}"
        puts "\nText: #{reading.text}"
        puts "\n"
      end
    end

    def get_bulk_annual_readings(years)
      years.between?(1950, 2050) || raise('Year must be between 1950 and 2050')
      # write files for # of years with each file containing all lectionary readings for that year (months 1 - 12)
      # #(O(Y) large linear time complexity, with bottleneck being web service and DB lookup when verses_only = false => O(Y X NETWORK X DB)
      years.each do |year|
        File.open("./readings/oca_lectionary_readings_#{year}.txt", 'w') do |file|
          (1..12).to_a.each do |month|
            scraper.get_bulk_monthly_readings(year, month, false).each do |reading|
              file.puts reading.to_s # todo, save to db
              file.puts "\n"
              file.puts "\n"
            end
          end
        end
      end
    end

    def get_bulk_monthly_readings(year, month, verses_only = true)
      #readings = nil
      request = HTTParty.get("#{SCRAPE_SERVE_API}/table?url=https://www.oca.org/readings/monthly/#{Today.year}/#{Today.month}")
      # The lectionary readings are stored in an HTML table, our Scraper microservice (Go Colly) extracts tables via the /table handler.
      table_readings = request.parsed_response['TableText'].split("\n").map(&:strip).reject(&:empty?)

      readings = self.manually_strip(table_readings) #unless verse_server_is_online

      # Readings may not be in the format that the verse server expects and the OCA site contains additional metadata that isn't a valid reference (ie, "(Matins)")
      # So we must pattern match and strip out just the references formatted properly into Bible::Reference objects.
      # # Query the verseserve API for KJV text of the verses and not have to worry about manually
      # constructing/parsing the reference here, from the table data. We can just pass it through as is..
      # curl http://127.0.0.1:7777/verse?ref=Acts%2:1-11
      #(TODO, 4-8-26) => Go server having an issue with something => add new debug statements
      #[=]VERSE SERVE[=]http: panic serving 127.0.0.1:40102: runtime error: invalid memory address or nil pointer dereference
      #http: panic serving 127.0.0.1:33998: runtime error: makeslice: len out of range
      if verse_server_is_online and verses_only == true
        api_readings = [] #references delivered from Go server
        finished_readings = [] #collection of Reference objects, properly formatted, to be finally returned
        readings.each do |reading|
          parsed_reference = "#{reading.book}%20#{reading.chapter}:#{reading.verses}"
          puts parsed_reference if @debug_is_enabled
          reference_response = HTTParty.get("#{VERSE_SERVE_API}/verse?ref=#{parsed_reference}")
          if reference_response.success?
            #If successful response, extract the text content from the JSON collection returned
            verse_text = reference_response.parsed_response['Verses']
            puts verse_text if @debug_is_enabled
            api_readings.push(verse_text)
          end
          rescue EOFError
            puts "CANT GET RESPONSE - SKIPPING (check verseserve logs)" 
          ensure 
            next
        end
        readings.zip(api_readings).map do |ref, text|
          ref = "no ref::error" if ref.nil?
          finished_readings.push(Bible::Reference.new(ref, text))
        rescue ArgumentError
          #There are objects being returned that don't have valid ref or text elements, could be a result of .zip?
          #Just ignore them and move on
        ensure
          next
        end
      end
      return finished_readings if verses_only == true or get_offline_readings(readings, './KJV.db')
    end

    private

    def manually_strip(readings)
      reading_list = []
      readings.each do |reading|
        puts reading
        # parse the book and verse chapters from the string
        # example string: "Acts 2:1-11"
        next unless reading =~ /(\w+)\s+(\d+:\d+-\d+)/

        # RegExp.last_match(1)
        book = $1
        # at first the 'verses' also contains the book, we'll strip that out
        verses = $2
        chapter = verses.split(':').first
        # now reassign verses from the initial variable with the chapter part removed
        verses = verses.split(':').last
        puts "Book: #{book},  Chapter: #{chapter}, Verses: #{verses}"
        b = Bible::Reference.new(book, chapter, verses)
        reading_list.push(b)
      end
      reading_list
    end

    def website_is_reachable?  
      response = HTTParty.get(@url)
      raise "Failed to reach #{@url}. HTTP Status: #{response.code}" unless response.success?
    rescue StandardError => e
      puts "Error reaching #{@url}: #{e.message}"
      exit(1)
    end

    def verse_server_is_online
      response = HTTParty.get("#{VERSE_SERVE_API}/health")#TODO
      if response.success?
        Scrapers::ServiceUtils.debug_log('VerseServe API is online and reachable.')
        true
      else
        Scrapers::ServiceUtils.debug_log('VerseServe API is not reachable. Falling back to manual parsing of readings without verse text.')
        false
      end
    rescue StandardError => e
      Scrapers::ServiceUtils.debug_log("Error reaching VerseServe API: #{e.message}. Falling back to manual parsing of readings without verse text.")
      # `./home/dpauley/Documents/Code/Apps/Ruby/daily_bread/verseserve`
    end

    # TODO: - this will probably be what we use
    # todo, should be an easier way for what I'm wanting
    def get_offline_readings(reading_list = [], db_name = './KJV.db')
      # make sure a .db file exists on the file system of the current working directory
      if File.exist?(db_name)
        Scrapers::ServiceUtils.debug_log('Local database found, querying for readings...')
        # query the database for the readings for the given month and year
        # this is just a placeholder, we would need to implement the actual database schema and query logic
        repo = LocalKJV.new(db_name)
        offline_readings = []
        reading_list.each do |reading|
          reference = "#{reading.book} #{reading.chapter}:#{reading.verses}"
          puts reference if @debug_is_enabled
          ref_reading = repo.get_kjv_reading(reading.book, reading.chapter, reading.verses)
          offline_readings.push(Bible::Reading.new(reference, ref_reading[:text]))
        end
        Scrapers::ServiceUtils.debug_log("Readings from from local database:\n#{offline_readings}")
        offline_readings
      else
        Scrapers::ServiceUtils.debug_log('No local database found, please run in online mode first to scrape and save the readings.')
        []
      end
    end
  end
end
