require_relative 'lectionary'

scraper = Scrapers::OCALectionary.new
scraper.load_readings
scraper.get_page_info
puts "\n== OCA Daily Scripture Readings ==\n"
puts "There are #{scraper.daily_reading_count} Scripture Readings.\n"
puts "Links:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.link
  #Scrapers::ServiceUtils.post_to_markdown_service(reading.link)
end
puts "Daily Reading Texts:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.text
end


#testing
scraper.get_bulk_monthly_readings(2026, 6)

