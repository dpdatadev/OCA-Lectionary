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

#write 7 files for each year with each file containing all lectionary readings for that year (months 1 - 12)
[2020, 2021, 2022, 2023, 2024, 2025, 2026].each do |year|
  File.open("./readings/oca_lectionary_readings_#{year}.txt", "w") do |file|
    (1..12).to_a.each do |month|
      scraper.get_bulk_monthly_readings(year, month, verses_only = false).each do |reading|
        file.puts reading.to_s
        file.puts "\n"
        file.puts "\n"
      end
    end
  end
end

#testing single kjv lookup reading
#todo create orthodox lectionary tables in local sqlite database according to website and build with local KJV text, basically an ETL job
#todo may remove the scrapeserve executable for this project, nokogiri is fast enough at scraping links
#db = LocalKJV.new
#db.debug = false

#reading = db.get_kjv_reading("Romans", "14", "9-18")
#daily_reading = Bible::Reading.new(reading[:ref_text], reading[:text])
#p daily_reading.to_s


