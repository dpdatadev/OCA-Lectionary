Eastern Orthodox Christians read scriptures on a seasonal (annual and daily) rotation of readings according to the Feasts and Liturgical cycles of the Church. 

This program uses HTTParty, Nokogiri, and SQLITE for super fast lookup and displaying these liturgical readings for the day, or month, or year, in ones application or for exporting to text/md.

__This project is not yet a GEM. ALPHA development (early iteration)__

```ruby
require 'lectionary'

scraper = Scrapers::OCALectionary.new
scraper.load_readings
scraper.get_page_info
puts "\n== OCA Daily Scripture Readings ==\n"
puts "There are #{scraper.daily_reading_count} Scripture Readings.\n"
puts "Links:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.link
  # If you run the ./scrapeserve executable then you can archive live readings (readings scraped with nokogiri as opposed to db lookup) to markdown
  # A local directory called ./md will be created with the files inside
  Scrapers::ServiceUtils.post_to_markdown_service(reading.link)
end
puts "Daily Reading Texts:\n"
scraper.daily_reading_links.each do |reading|
  puts reading.text
end


#get the whole lectionary cycle for April 2026
#if verses_only were set to true, then only a collection of the scripture references would be returned
#in this case (verses_only = false), the actual reading objects with full text from the local database will be returned on screen
# you can iterate over these Reading objects to direct text wherever it needs to go, including converting to HTML or Markdown for your Rails app etc.,
scraper.get_bulk_monthly_readings(2026, 4, verses_only = false)

#or..
#lets write 7 files for each year with each file containing all lectionary readings for that year (months 1 - 12)
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

#Single kjv lookup reading
db = LocalKJV.new
db.debug = false
pp db.get_kjv_reading("Romans", "14", "9-18")

# CHRIST IS KING

#contact:
#dpdatadev@gmail.com
```

This program optionally uses, and can further be enhanced by, utilizing these single file Go servers:
[VerseServe](https://github.com/dpdatadev/VerseServe)
[ScrapeServe](https://github.com/dpdatadev/ScrapeServe)
