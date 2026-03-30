# frozen_string_literal: true
# version, 0.0.1 ALPHA


require 'sqlite3'
require 'sequel'

class LocalKJV 
  attr_reader :db
  attr_writer :debug

  def initialize(db_file = 'KJV.db')
    @db = Sequel.sqlite(db_file)
    @debug = true
  end

  def get_kjv_reading(book, chapter, verses)
    ref_text = "Reading from the Book of #{book}, #{chapter} #{verses}"
    puts "Getting reading for #{book} #{chapter}:#{verses} from local database..."
     
    start_verse, end_verse = verses.split('-').map(&:to_i) #convert the start and end verse to integers
    verse_list = (start_verse..end_verse).to_a #ie Matthew 5:3-10 would be split into an array of verses [3,4,5,6,7,8,9,10]
     
    verses_str = verse_list.join(', ')
    query = "select b.`name` as `book`, v.`chapter`, v.`verse`, v.`text` 
              from KJV_Verses v 
              inner join KJV_Books b on v.book_id = b.id
              where b.`name` = '#{book}'
              and   v.`chapter` = #{chapter}
              and   v.`verse` in (#{verses_str})
              order by v.`chapter`, v.`verse` ASC"
    puts query if @debug
    reading_map = {ref_text: ref_text, text: @db[query].map { |row| row[:text] }.join(' ')}
    return reading_map
  end
end