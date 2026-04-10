# API testing
# 3-30-2026
require_relative 'lectionary'

scraper = Scrapers::OCALectionary.new
scraper.debug_is_enabled = true
scraper.dump_daily_readings = true #this sets all outputs to be dumped to disk
scraper.get_page_info
scraper.load_readings

#Show troparion for today
scraper.show_troparia

#Or you can craft a custom date and pass it to the scraper
#scraper.show_troparia(timeframe=Scrapers::Today.days_from(7))



puts "\n== OCA Daily Scripture Readings ==\n".colorize(:blue)
puts "There are #{scraper.daily_reading_count} Scripture Readings.\n"
puts "Links:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.link.colorize(:yellow)
  #Scrapers::ServiceUtils.post_to_markdown_service(reading.link)
end

puts "Daily Reading Texts:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.text.colorize(:yellow)
end


#get one lectionary month 
#scraper.get_bulk_monthly_readings(2026, 4, verses_only = false)
#or..

#testing single kjv lookup reading
#todo create orthodox lectionary tables in local sqlite database according to website and build with local KJV text, basically an ETL job
#todo may remove the scrapeserve executable for this project, nokogiri is fast enough at scraping links
#db = LocalKJV.new
#db.debug = false

#reading = db.get_kjv_reading("Romans", "14", "9-18")
#daily_reading = Bible::Reading.new(reading[:ref_text], reading[:text])
#p daily_reading.to_s


