# API testing
# 3-30-2026
require_relative 'lectionary'

scraper = Scrapers::OCALectionary.new
#scraper.debug_is_enabled = true
scraper.dump_daily_readings = true
scraper.get_page_info
scraper.load_readings
=begin
puts "\n== OCA Daily Scripture Readings ==\n"
puts "There are #{scraper.daily_reading_count} Scripture Readings.\n"
puts "Links:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.link
  #Scrapers::ServiceUtils.post_to_markdown_service(reading.link)
end
=end
=begin
puts "Daily Reading Texts:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.text
end
=end

#get one lectionary month 

#scraper.get_bulk_monthly_readings(2026, 4, verses_only = true)
#or..

#testing single kjv lookup reading
#todo create orthodox lectionary tables in local sqlite database according to website and build with local KJV text, basically an ETL job
#todo may remove the scrapeserve executable for this project, nokogiri is fast enough at scraping links
#db = LocalKJV.new
#db.debug = false

#reading = db.get_kjv_reading("Romans", "14", "9-18")
#daily_reading = Bible::Reading.new(reading[:ref_text], reading[:text])
#p daily_reading.to_s


