# frozen_string_literal: true
# TODO - work in progress
module BibleBot
  class BibleBotError < StandardError
  end

  # Raised if Reference is not valid.
  # @example
  #   "Genesis 4-2"
  class InvalidReferenceError < BibleBotError
  end

  # Raised if Verse is not valid.
  # In other words, if a chapter or verse are referenced that don't actually exist.
  # @example
  #   "Genesis 100:2"
  class InvalidVerseError < BibleBotError
  end
  # Defines Books and Regular Expressions used for parsing and other logic in this gem.
  class Bible
    FIRST = %w[1 1st I First One].freeze
    SECOND = %w[2 2nd II Second Two].freeze
    THIRD = %w[3 3rd III Third Three].freeze
    FOURTH = %w[4 4th IV Fourth Four].freeze

    FIRST_PREFIX, SECOND_PREFIX, THIRD_PREFIX, FOURTH_PREFIX = [FIRST, SECOND, THIRD, FOURTH].map do |prefixes|
      "(?:#{prefixes.join('|')})(?:\\s)?"
    end

    # "John" should not match the numbered John books (1 John, 2 John, 3 John)
    # Lookbehind regex statements have to be a fixed length. Since all of the prefix strings are
    # different lengths ("I", "1st", "First"), we can't do it all in 1 lookbehind, but we can build
    # a complex regex that contains all permutations of lookbehinds.
    # https://stackoverflow.com/a/2126755
    JOHN_PREFIX = [FIRST, SECOND, THIRD]
      .flatten
      .map { |word| "(?<!#{word})(?<!#{word}\\s)" }
      .join

    # Using this list to inform some of the Abbreviation decisions: https://www.logos.com/bible-book-abbreviations
    # DBL Codes are from https://app.thedigitalbiblelibrary.org/static/docs/entryref/text/metadata.html#vocab-bookcode
    @@books = [
      Book.new(
        id: 1,
        name: "Genesis",
        abbreviation: "Gen",
        dbl_code: "GEN",
        regex: "(?:Gen|Ge|Gn)(?:esis)?",
        testament: :old_testament,
        chapters: [31, 25, 24, 26, 32, 22, 24, 22, 29, 32, 32, 20, 18, 24, 21, 16, 27, 33, 38, 18, 34, 24, 20, 67, 34, 35, 46, 22, 35, 43, 55, 32, 20, 31, 29, 43, 36, 30, 23, 23, 57, 38, 34, 34, 28, 34, 31, 22, 33, 26]
      ),
      Book.new(
        id: 2,
        name: "Exodus",
        abbreviation: "Exod",
        dbl_code: "EXO",
        regex: "Ex(?:odus|od|o)?",
        testament: :old_testament,
        chapters: [22, 25, 22, 31, 23, 30, 25, 32, 35, 29, 10, 51, 22, 31, 27, 36, 16, 27, 25, 26, 36, 31, 33, 18, 40, 37, 21, 43, 46, 38, 18, 35, 23, 35, 35, 38, 29, 31, 43, 38]
      ),
      Book.new(
        id: 3,
        name: "Leviticus",
        abbreviation: "Lev",
        dbl_code: "LEV",
        regex: "(?:Lev|Le|Lv)(?:iticus)?",
        testament: :old_testament,
        chapters: [17, 16, 17, 35, 19, 30, 38, 36, 24, 20, 47, 8, 59, 57, 33, 34, 16, 30, 37, 27, 24, 33, 44, 23, 55, 46, 34]
      ),
      Book.new(
        id: 4,
        name: "Numbers",
        abbreviation: "Num",
        dbl_code: "NUM",
        regex: "N(?:umbers|um|u|m|b)",
        testament: :old_testament,
        chapters: [54, 34, 51, 49, 31, 27, 89, 26, 23, 36, 35, 16, 33, 45, 41, 50, 13, 32, 22, 29, 35, 41, 30, 25, 18, 65, 23, 31, 40, 16, 54, 42, 56, 29, 34, 13]
      ),
      Book.new(
        id: 5,
        name: "Deuteronomy",
        abbreviation: "Deut",
        dbl_code: "DEU",
        regex: "D(?:euteronomy|eut|e|t)",
        testament: :old_testament,
        chapters: [46, 37, 29, 49, 33, 25, 26, 20, 29, 22, 32, 32, 18, 29, 23, 22, 20, 22, 21, 20, 23, 30, 25, 22, 19, 19, 26, 68, 29, 20, 30, 52, 29, 12]
      ),
      Book.new(
        id: 6,
        name: "Joshua",
        abbreviation: "Josh",
        dbl_code: "JOS",
        regex: "J(?:oshua|osh|os|sh)",
        testament: :old_testament,
        chapters: [18, 24, 17, 24, 15, 27, 26, 35, 27, 43, 23, 24, 33, 15, 63, 10, 18, 28, 51, 9, 45, 34, 16, 33]
      ),
      Book.new(
        id: 7,
        name: "Judges",
        abbreviation: "Judg",
        dbl_code: "JDG",
        regex: "J(?:udges|udg|dg|g|dgs)",
        testament: :old_testament,
        chapters: [36, 23, 31, 24, 31, 40, 25, 35, 57, 18, 40, 15, 25, 20, 20, 31, 13, 31, 30, 48, 25]
      ),
      Book.new(
        id: 8,
        name: "Ruth",
        abbreviation: "Ruth",
        dbl_code: "RUT",
        regex: "R(?:uth|u|th)",
        testament: :old_testament,
        chapters: [22, 23, 18, 22]
      ),
      Book.new(
        id: 9,
        name: "1 Samuel",
        abbreviation: "1Sam",
        dbl_code: "1SA",
        regex: "#{FIRST_PREFIX}S(?:amuel|am|m)",
        testament: :old_testament,
        chapters: [28, 36, 21, 22, 12, 21, 17, 22, 27, 27, 15, 25, 23, 52, 35, 23, 58, 30, 24, 42, 15, 23, 29, 22, 44, 25, 12, 25, 11, 31, 13]
      ),
      Book.new(
        id: 10,
        name: "2 Samuel",
        abbreviation: "2Sam",
        dbl_code: "2SA",
        regex: "#{SECOND_PREFIX}S(?:amuel|am|m)",
        testament: :old_testament,
        chapters: [27, 32, 39, 12, 25, 23, 29, 18, 13, 19, 27, 31, 39, 33, 37, 23, 29, 33, 43, 26, 22, 51, 39, 25]
      ),
      Book.new(
        id: 11,
        name: "1 Kings",
        abbreviation: "1Kgs",
        dbl_code: "1KI",
        regex: "#{FIRST_PREFIX}K(?:in)?gs",
        testament: :old_testament,
        chapters: [53, 46, 28, 34, 18, 38, 51, 66, 28, 29, 43, 33, 34, 31, 34, 34, 24, 46, 21, 43, 29, 53]
      ),
      Book.new(
        id: 12,
        name: "2 Kings",
        abbreviation: "2Kgs",
        dbl_code: "2KI",
        regex: "#{SECOND_PREFIX}K(?:in)?gs",
        testament: :old_testament,
        chapters: [18, 25, 27, 44, 27, 33, 20, 29, 37, 36, 21, 21, 25, 29, 38, 20, 41, 37, 37, 21, 26, 20, 37, 20, 30]
      ),
      Book.new(
        id: 13,
        name: "1 Chronicles",
        abbreviation: "1Chr",
        dbl_code: "1CH",
        regex: "#{FIRST_PREFIX}Chr(?:on)?(?:icles)?",
        testament: :old_testament,
        chapters: [54, 55, 24, 43, 26, 81, 40, 40, 44, 14, 47, 40, 14, 17, 29, 43, 27, 17, 19, 8, 30, 19, 32, 31, 31, 32, 34, 21, 30]
      ),
      Book.new(
        id: 14,
        name: "2 Chronicles",
        abbreviation: "2Chr",
        dbl_code: "2CH",
        regex: "#{SECOND_PREFIX}Chr(?:on)?(?:icles)?",
        testament: :old_testament,
        chapters: [17, 18, 17, 22, 14, 42, 22, 18, 31, 19, 23, 16, 22, 15, 19, 14, 19, 34, 11, 37, 20, 12, 21, 27, 28, 23, 9, 27, 36, 27, 21, 33, 25, 33, 27, 23]
      ),
      Book.new(
        id: 15,
        name: "Ezra",
        abbreviation: "Ezra",
        dbl_code: "EZR",
        regex: "Ez(?:ra|r)",
        testament: :old_testament,
        chapters: [11, 70, 13, 24, 17, 22, 28, 36, 15, 44]
      ),
      Book.new(
        id: 16,
        name: "Nehemiah",
        abbreviation: "Neh",
        dbl_code: "NEH",
        regex: "Ne(?:hemiah|h)?",
        testament: :old_testament,
        chapters: [11, 20, 32, 23, 19, 19, 73, 18, 38, 39, 36, 47, 31]
      ),
      Book.new(
        id: 17,
        name: "Esther",
        abbreviation: "Esth",
        dbl_code: "EST",
        regex: "Es(?:ther|th|t|h)?",
        testament: :old_testament,
        chapters: [22, 23, 15, 17, 14, 14, 10, 17, 32, 3]
      ),
      Book.new(
        id: 18,
        name: "Job",
        abbreviation: "Job",
        dbl_code: "JOB",
        regex: "Jo?b",
        testament: :old_testament,
        chapters: [22, 13, 26, 21, 27, 30, 21, 22, 35, 22, 20, 25, 28, 22, 35, 22, 16, 21, 29, 29, 34, 30, 17, 25, 6, 14, 23, 28, 25, 31, 40, 22, 33, 37, 16, 33, 24, 41, 30, 24, 34, 17]
      ),
      Book.new(
        id: 19,
        name: "Psalms",
        abbreviation: "Ps",
        dbl_code: "PSA",
        regex: "Ps(?:alms|alm|s|m|a)?",
        testament: :old_testament,
        chapters: [6, 12, 8, 8, 12, 10, 17, 9, 20, 18, 7, 8, 6, 7, 5, 11, 15, 50, 14, 9, 13, 31, 6, 10, 22, 12, 14, 9, 11, 12, 24, 11, 22, 22, 28, 12, 40, 22, 13, 17, 13, 11, 5, 26, 17, 11, 9, 14, 20, 23, 19, 9, 6, 7, 23, 13, 11, 11, 17, 12, 8, 12, 11, 10, 13, 20, 7, 35, 36, 5, 24, 20, 28, 23, 10, 12, 20, 72, 13, 19, 16, 8, 18, 12, 13, 17, 7, 18, 52, 17, 16, 15, 5, 23, 11, 13, 12, 9, 9, 5, 8, 28, 22, 35, 45, 48, 43, 13, 31, 7, 10, 10, 9, 8, 18, 19, 2, 29, 176, 7, 8, 9, 4, 8, 5, 6, 5, 6, 8, 8, 3, 18, 3, 3, 21, 26, 9, 8, 24, 13, 10, 7, 12, 15, 21, 10, 20, 14, 9, 6]
      ),
      Book.new(
        id: 20,
        name: "Proverbs",
        abbreviation: "Prov",
        dbl_code: "PRO",
        regex: "Pr(?:overbs|ov|o|v)?",
        testament: :old_testament,
        chapters: [33, 22, 35, 27, 23, 35, 27, 36, 18, 32, 31, 28, 25, 35, 33, 33, 28, 24, 29, 30, 31, 29, 35, 34, 28, 28, 27, 28, 27, 33, 31]
      ),
      Book.new(
        id: 21,
        name: "Ecclesiastes",
        abbreviation: "Eccl",
        dbl_code: "ECC",
        regex: "Ec(?:clesiastes|cles|cle|cl|c)?",
        testament: :old_testament,
        chapters: [18, 26, 22, 16, 20, 12, 29, 17, 18, 20, 10, 14]
      ),
      Book.new(
        id: 22,
        name: "Song of Solomon",
        abbreviation: "Song",
        dbl_code: "SNG",
        regex: "Songs?(?: of )?(?:Solomon|Songs)?",
        testament: :old_testament,
        chapters: [17, 17, 11, 16, 16, 13, 13, 14]
      ),
      Book.new(
        id: 23,
        name: "Isaiah",
        abbreviation: "Isa",
        dbl_code: "ISA",
        regex: "Is(?:a|aiah)?",
        testament: :old_testament,
        chapters: [31, 22, 26, 6, 30, 13, 25, 22, 21, 34, 16, 6, 22, 32, 9, 14, 14, 7, 25, 6, 17, 25, 18, 23, 12, 21, 13, 29, 24, 33, 9, 20, 24, 17, 10, 22, 38, 22, 8, 31, 29, 25, 28, 28, 25, 13, 15, 22, 26, 11, 23, 15, 12, 17, 13, 12, 21, 14, 21, 22, 11, 12, 19, 12, 25, 24]
      ),
      Book.new(
        id: 24,
        name: "Jeremiah",
        abbreviation: "Jer",
        dbl_code: "JER",
        regex: "J(?:eremiah|e|er|r)",
        testament: :old_testament,
        chapters: [19, 37, 25, 31, 31, 30, 34, 22, 26, 25, 23, 17, 27, 22, 21, 21, 27, 23, 15, 18, 14, 30, 40, 10, 38, 24, 22, 17, 32, 24, 40, 44, 26, 22, 19, 32, 21, 28, 18, 16, 18, 22, 13, 30, 5, 28, 7, 47, 39, 46, 64, 34]
      ),
      Book.new(
        id: 25,
        name: "Lamentations",
        abbreviation: "Lam",
        dbl_code: "LAM",
        regex: "Lam(?:entations)?",
        testament: :old_testament,
        chapters: [22, 22, 66, 22, 22]
      ),
      Book.new(
        id: 26,
        name: "Ezekiel",
        abbreviation: "Ezek",
        dbl_code: "EZK",
        regex: "Ezek(?:iel)?",
        testament: :old_testament,
        chapters: [28, 10, 27, 17, 17, 14, 27, 18, 11, 22, 25, 28, 23, 23, 8, 63, 24, 32, 14, 49, 32, 31, 49, 27, 17, 21, 36, 26, 21, 26, 18, 32, 33, 31, 15, 38, 28, 23, 29, 49, 26, 20, 27, 31, 25, 24, 23, 35]
      ),
      Book.new(
        id: 27,
        name: "Daniel",
        abbreviation: "Dan",
        dbl_code: "DAN",
        regex: "Dan(?:iel)?",
        testament: :old_testament,
        chapters: [21, 49, 30, 37, 31, 28, 28, 27, 27, 21, 45, 13]
      ),
      Book.new(
        id: 28,
        name: "Hosea",
        abbreviation: "Hos",
        dbl_code: "HOS",
        regex: "Hos(?:ea)?",
        testament: :old_testament,
        chapters: [11, 23, 5, 19, 15, 11, 16, 14, 17, 15, 12, 14, 16, 9]
      ),
      Book.new(
        id: 29,
        name: "Joel",
        abbreviation: "Joel",
        dbl_code: "JOL",
        regex: "Joel",
        testament: :old_testament,
        chapters: [20, 32, 21]
      ),
      Book.new(
        id: 30,
        name: "Amos",
        abbreviation: "Amos",
        dbl_code: "AMO",
        regex: "Amos",
        testament: :old_testament,
        chapters: [15, 16, 15, 13, 27, 14, 17, 14, 15]
      ),
      Book.new(
        id: 31,
        name: "Obadiah",
        abbreviation: "Obad",
        dbl_code: "OBA",
        regex: "Obad(?:iah)?",
        testament: :old_testament,
        chapters: [21]
      ),
      Book.new(
        id: 32,
        name: "Jonah",
        abbreviation: "Jonah",
        dbl_code: "JON",
        regex: "Jonah",
        testament: :old_testament,
        chapters: [17, 10, 10, 11]
      ),
      Book.new(
        id: 33,
        name: "Micah",
        abbreviation: "Mic",
        dbl_code: "MIC",
        regex: "Mic(?:ah)?",
        testament: :old_testament,
        chapters: [16, 13, 12, 13, 15, 16, 20]
      ),
      Book.new(
        id: 34,
        name: "Nahum",
        abbreviation: "Nah",
        dbl_code: "NAM",
        regex: "Nah(?:um)?",
        testament: :old_testament,
        chapters: [15, 13, 19]
      ),
      Book.new(
        id: 35,
        name: "Habakkuk",
        abbreviation: "Hab",
        dbl_code: "HAB",
        regex: "Hab(?:akkuk)?",
        testament: :old_testament,
        chapters: [17, 20, 19]
      ),
      Book.new(
        id: 36,
        name: "Zephaniah",
        abbreviation: "Zeph",
        dbl_code: "ZEP",
        regex: "Z(?:ephaniah|eph|ep|p)",
        testament: :old_testament,
        chapters: [18, 15, 20]
      ),
      Book.new(
        id: 37,
        name: "Haggai",
        abbreviation: "Hag",
        dbl_code: "HAG",
        regex: "Hag(?:gai)?",
        testament: :old_testament,
        chapters: [15, 23]
      ),
      Book.new(
        id: 38,
        name: "Zechariah",
        abbreviation: "Zech",
        dbl_code: "ZEC",
        regex: "Zech(?:ariah)?",
        testament: :old_testament,
        chapters: [21, 13, 10, 14, 11, 15, 14, 23, 17, 12, 17, 14, 9, 21]
      ),
      Book.new(
        id: 39,
        name: "Malachi",
        abbreviation: "Mal",
        dbl_code: "MAL",
        regex: "Mal(?:achi)?",
        testament: :old_testament,
        chapters: [14, 17, 18, 6]
      ),
      Book.new(
        id: 40,
        name: "Matthew",
        abbreviation: "Matt",
        dbl_code: "MAT",
        regex: "M(?:atthew|t|at|att)",
        testament: :new_testament,
        chapters: [25, 23, 17, 25, 48, 34, 29, 34, 38, 42, 30, 50, 58, 36, 39, 28, 27, 35, 30, 34, 46, 46, 39, 51, 46, 75, 66, 20]
      ),
      Book.new(
        id: 41,
        name: "Mark",
        abbreviation: "Mark",
        dbl_code: "MRK",
        regex: "M(?:k|ark)",
        testament: :new_testament,
        chapters: [45, 28, 35, 41, 43, 56, 37, 38, 50, 52, 33, 44, 37, 72, 47, 20]
      ),
      Book.new(
        id: 42,
        name: "Luke",
        abbreviation: "Luke",
        dbl_code: "LUK",
        regex: "(?:Luke|Lk)",
        testament: :new_testament,
        chapters: [80, 52, 38, 44, 39, 49, 50, 56, 62, 42, 54, 59, 35, 35, 32, 31, 37, 43, 48, 47, 38, 71, 56, 53]
      ),
      Book.new(
        id: 43,
        name: "John",
        abbreviation: "John",
        dbl_code: "JHN",
        regex: "#{JOHN_PREFIX}(?:John|Jhn|Jn)",
        testament: :new_testament,
        chapters: [51, 25, 36, 54, 47, 71, 53, 59, 41, 42, 57, 50, 38, 31, 27, 33, 26, 40, 42, 31, 25]
      ),
      Book.new(
        id: 44,
        name: "Acts",
        abbreviation: "Acts",
        dbl_code: "ACT",
        regex: "(?:Acts|Ac)",
        testament: :new_testament,
        chapters: [26, 47, 26, 37, 42, 15, 60, 40, 43, 48, 30, 25, 52, 28, 41, 40, 34, 28, 41, 38, 40, 30, 35, 27, 27, 32, 44, 31]
      ),
      Book.new(
        id: 45,
        name: "Romans",
        abbreviation: "Rom",
        dbl_code: "ROM",
        regex: "(?:Rom|Rm)(?:ans)?",
        testament: :new_testament,
        chapters: [32, 29, 31, 25, 21, 23, 25, 39, 33, 21, 36, 21, 14, 23, 33, 27]
      ),
      Book.new(
        id: 46,
        name: "1 Corinthians",
        abbreviation: "1Cor",
        dbl_code: "1CO",
        regex: "#{FIRST_PREFIX}Cor(?:inthians)?",
        testament: :new_testament,
        chapters: [31, 16, 23, 21, 13, 20, 40, 13, 27, 33, 34, 31, 13, 40, 58, 24]
      ),
      Book.new(
        id: 47,
        name: "2 Corinthians",
        abbreviation: "2Cor",
        dbl_code: "2CO",
        regex: "#{SECOND_PREFIX}Cor(?:inthians)?",
        testament: :new_testament,
        chapters: [24, 17, 18, 18, 21, 18, 16, 24, 15, 18, 33, 21, 14]
      ),
      Book.new(
        id: 48,
        name: "Galatians",
        abbreviation: "Gal",
        dbl_code: "GAL",
        regex: "Gal(?:atians)?",
        testament: :new_testament,
        chapters: [24, 21, 29, 31, 26, 18]
      ),
      Book.new(
        id: 49,
        name: "Ephesians",
        abbreviation: "Eph",
        dbl_code: "EPH",
        regex: "Eph(?:esians)?",
        testament: :new_testament,
        chapters: [23, 22, 21, 32, 33, 24]
      ),
      Book.new(
        id: 50,
        name: "Philippians",
        abbreviation: "Phil",
        dbl_code: "PHP",
        regex: "Phil(?!e)(?:ippians)?",
        testament: :new_testament,
        chapters: [30, 30, 21, 23]
      ),
      Book.new(
        id: 51,
        name: "Colossians",
        abbreviation: "Col",
        dbl_code: "COL",
        regex: "Col(?:ossians)?",
        testament: :new_testament,
        chapters: [29, 23, 25, 18]
      ),
      Book.new(
        id: 52,
        name: "1 Thessalonians",
        abbreviation: "1Thess",
        dbl_code: "1TH",
        regex: "#{FIRST_PREFIX}Th(?:es)?(?:s)?(?:alonians)?",
        testament: :new_testament,
        chapters: [10, 20, 13, 18, 28]
      ),
      Book.new(
        id: 53,
        name: "2 Thessalonians",
        abbreviation: "2Thess",
        dbl_code: "2TH",
        regex: "#{SECOND_PREFIX}Th(?:es)?(?:s)?(?:alonians)?",
        testament: :new_testament,
        chapters: [12, 17, 18]
      ),
      Book.new(
        id: 54,
        name: "1 Timothy",
        abbreviation: "1Tim",
        dbl_code: "1TI",
        regex: "#{FIRST_PREFIX}Tim(?:othy)?",
        testament: :new_testament,
        chapters: [20, 15, 16, 16, 25, 21]
      ),
      Book.new(
        id: 55,
        name: "2 Timothy",
        abbreviation: "2Tim",
        dbl_code: "2TI",
        regex: "#{SECOND_PREFIX}Tim(?:othy)?",
        testament: :new_testament,
        chapters: [18, 26, 17, 22]
      ),
      Book.new(
        id: 56,
        name: "Titus",
        abbreviation: "Titus",
        dbl_code: "TIT",
        regex: "Tit(?:us)?",
        testament: :new_testament,
        chapters: [16, 15, 15]
      ),
      Book.new(
        id: 57,
        name: "Philemon",
        abbreviation: "Philem",
        dbl_code: "PHM",
        regex: "(?:Philemon|Philem|Phlmn)",
        testament: :new_testament,
        chapters: [25]
      ),
      Book.new(
        id: 58,
        name: "Hebrews",
        abbreviation: "Heb",
        dbl_code: "HEB",
        regex: "Heb(?:rews)?",
        testament: :new_testament,
        chapters: [14, 18, 19, 16, 14, 20, 28, 13, 28, 39, 40, 29, 25]
      ),
      Book.new(
        id: 59,
        name: "James",
        abbreviation: "Jas",
        dbl_code: "JAS",
        regex: "Ja(?:me)?s",
        testament: :new_testament,
        chapters: [27, 26, 18, 17, 20]
      ),
      Book.new(
        id: 60,
        name: "1 Peter",
        abbreviation: "1Pet",
        dbl_code: "1PE",
        regex: "#{FIRST_PREFIX}Pet(?:er)?",
        testament: :new_testament,
        chapters: [25, 25, 22, 19, 14]
      ),
      Book.new(
        id: 61,
        name: "2 Peter",
        abbreviation: "2Pet",
        dbl_code: "2PE",
        regex: "#{SECOND_PREFIX}Pet(?:er)?",
        testament: :new_testament,
        chapters: [21, 22, 18]
      ),
      Book.new(
        id: 62,
        name: "1 John",
        abbreviation: "1John",
        dbl_code: "1JN",
        regex: "#{FIRST_PREFIX}(?:John|Jhn|Jn)",
        testament: :new_testament,
        chapters: [10, 29, 24, 21, 21]
      ),
      Book.new(
        id: 63,
        name: "2 John",
        abbreviation: "2John",
        dbl_code: "2JN",
        regex: "#{SECOND_PREFIX}(?:John|Jhn|Jn)",
        testament: :new_testament,
        chapters: [13]
      ),
      Book.new(
        id: 64,
        name: "3 John",
        abbreviation: "3John",
        dbl_code: "3JN",
        regex: "#{THIRD_PREFIX}(?:John|Jhn|Jn)",
        testament: :new_testament,
        chapters: [15]
      ),
      Book.new(
        id: 65,
        name: "Jude",
        abbreviation: "Jude",
        dbl_code: "JUD",
        regex: "Jude",
        testament: :new_testament,
        chapters: [25]
      ),
      Book.new(
        id: 66,
        name: "Revelation",
        abbreviation: "Rev",
        dbl_code: "REV",
        regex: "Rev(?:elation)?(?:\\sof Jesus Christ)?",
        testament: :new_testament,
        chapters: [20, 29, 22, 11, 14, 17, 17, 13, 21, 11, 19, 17, 18, 20, 8, 21, 18, 24, 21, 15, 27, 21]
      )
    ]

    @@apocryphal_books = [
      Book.new(
        id: 101,
        name: "Tobit",
        abbreviation: "Tob",
        dbl_code: "TOB",
        regex: "(?:(Tb|Tob|Tobit))",
        testament: :apocrypha,
        chapters: [22, 14, 17, 21, 22, 18, 18, 21, 6, 13, 19, 22, 18, 15],
      ),
      Book.new(
        id: 102,
        name: "Judith",
        abbreviation: "Jth",
        dbl_code: "JDT",
        regex: "(?:(Jdt|Jth|Jdth|Judith))",
        testament: :apocrypha,
        chapters: [16, 28, 10, 15, 24, 21, 32, 36, 14, 23, 23, 20, 20, 19, 14, 25],
      ),
      Book.new(
        id: 103,
        name: "Additions to Esther",
        abbreviation: "Add Esth",
        dbl_code: "ESG",
        regex: "(?:(Add(itions)?(\\sto)?|(The\\s)?Rest\\sof|A)\\s*Est?h?e?r?)",
        testament: :apocrypha,
        chapters: [0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 12, 6, 18, 19, 16, 24],
      ),
      Book.new(
        id: 104,
        name: "Wisdom of Solomon",
        abbreviation: "Wis",
        dbl_code: "WIS",
        regex: "(?:(Wi?sd?(om)?(\\sof\\s)?(Sol|Solomon)?))",
        testament: :apocrypha,
        chapters: [16, 24, 19, 20, 23, 25, 30, 21, 18, 21, 26, 27, 19, 31, 19, 29, 21, 25, 22],
      ),
      Book.new(
        id: 105,
        name: "Sirach", # a.k.a. Ecclesiasticus
        abbreviation: "Sir",
        dbl_code: "SIR",
        regex: "(?:(Sir(?:ach)?)|Ecclus|Ecclesiasticus)",
        testament: :apocrypha,
        chapters: [30, 18, 31, 31, 15, 37, 36, 19, 18, 31, 34, 18, 26, 27, 20, 30, 32, 33, 30, 32, 28, 27, 28, 34, 26, 29, 30, 26, 28, 25, 31, 24, 33, 31, 26, 31, 31, 34, 35, 30, 24, 25, 33, 23, 26, 20, 25, 25, 16, 29, 30],
      ),
      Book.new(
        id: 106,
        name: "Baruch",
        abbreviation: "Bar",
        dbl_code: "BAR",
        regex: "(?:Bar(?:uch)?)",
        testament: :apocrypha,
        chapters: [22, 35, 37, 37, 9],
      ),
      Book.new(
        id: 107,
        name: "Letter of Jeremiah", # Often placed as Baruch 6, but sometimes stands alone
        abbreviation: "Ep Jer",
        dbl_code: "LJE",
        regex: "(?:(Letter of Jeremiah|Ep Jer|Let Jer|Ltr Jer|LJe))",
        testament: :apocrypha,
        chapters: [73],
      ),
      Book.new(
        id: 108,
        name: "Prayer of Azariah and the Song of the Three Jews", # An extension of Daniel 3... a.k.a. Prayer of Azariah
        abbreviation: "Sg of 3 Childr",
        dbl_code: "S3Y",
        regex: "(?:(?:Pr\\sAz|Prayer\\sof\\sAzariah|Azariah|(?:The\\s)?So?n?g\\s(?:of\\s)?(?:the\\s)?(?:3|Three|Thr)(?:\\s(?:Holy|Young)?\\s*(?:Childr(?:en)?|Jews))?))",
        testament: :apocrypha,
        chapters: [68],
      ),
      Book.new(
        id: 109,
        name: "Susanna", # A book of Daniel
        abbreviation: "Sus",
        dbl_code: "SUS",
        regex: "(?:Sus(?:anna)?)",
        testament: :apocrypha,
        chapters: [64],
      ),
      Book.new(
        id: 110,
        name: "Bel and the Dragon", # A book of Daniel
        abbreviation: "Bel and Dr",
        dbl_code: "BEL",
        regex: "(?:Bel(\\s(and\\sthe\\sDragon|and\\sDr))?)",
        testament: :apocrypha,
        chapters: [42],
      ),
      Book.new(
        id: 111,
        name: "1 Maccabees",
        abbreviation: "1 Macc",
        dbl_code: "1MA",
        regex: "(#{FIRST_PREFIX}(M|Ma|Mac|Macc|Maccabees))",
        testament: :apocrypha,
        chapters: [64, 70, 60, 61, 68, 63, 50, 32, 73, 89, 74, 53, 53, 49, 41, 24],
      ),
      Book.new(
        id: 112,
        name: "2 Maccabees",
        abbreviation: "2 Macc",
        dbl_code: "2MA",
        regex: "(#{SECOND_PREFIX}(M|Ma|Mac|Macc|Maccabees))",
        testament: :apocrypha,
        chapters: [36, 32, 40, 50, 27, 31, 42, 36, 29, 38, 38, 45, 26, 46, 39],
      ),
      Book.new(
        id: 113,
        name: "1 Esdras",
        abbreviation: "1 Esd",
        dbl_code: "1ES",
        regex: "(#{FIRST_PREFIX}(Esd|Esdr|Esdras))",
        testament: :apocrypha,
        chapters: [58, 30, 24, 63, 73, 34, 15, 96, 55],
      ),
      Book.new(
        id: 114,
        name: "Prayer of Manasseh",
        abbreviation: "Pr of Man",
        dbl_code: "MAN",
        regex: "(?:(Prayer\\sof\\sManasseh|Pr\\sof\\sMan|PMa|Prayer\\sof\\sManasses))",
        testament: :apocrypha,
        chapters: [15],
      ),
      Book.new(
        id: 115,
        name: "Psalm 151",
        abbreviation: "Psalm 151",
        dbl_code: "PS2",
        regex: "(?:Ps(?:alms|alm|s|m|a)?\\s151)",
        testament: :apocrypha,
        chapters: [7],
      ),
      Book.new(
        id: 116,
        name: "3 Maccabees",
        abbreviation: "3 Macc",
        dbl_code: "3MA",
        regex: "(#{THIRD_PREFIX}(M|Ma|Mac|Macc|Maccabees))",
        testament: :apocrypha,
        chapters: [29, 33, 30, 21, 51, 41, 23],
      ),
      Book.new(
        id: 117,
        name: "2 Esdras",
        abbreviation: "2 Esd",
        dbl_code: "2ES",
        regex: "(#{SECOND_PREFIX}(Esd|Esdr|Esdras))",
        testament: :apocrypha,
        chapters: [40, 48, 36, 52, 56, 59, 140, 63, 47, 59, 46, 51, 58, 48, 63, 78],
      ),
      Book.new(
        id: 118,
        name: "4 Maccabees",
        abbreviation: "4 Macc",
        dbl_code: "4MA",
        regex: "(#{FOURTH_PREFIX}(M|Ma|Mac|Macc|Maccabees))",
        testament: :apocrypha,
        chapters: [35, 24, 21, 26, 38, 35, 23, 29, 32, 21, 27, 19, 27, 20, 32, 25, 24, 24],
      ),
    ]

    def self.books
      if BibleBot.include_apocryphal_content?
        # Apocryphal books have to come first, since there's some overlap in the regex, but
        # the apocryphal books are more verbose. "Song", "Esther", "Psalm"
        @@apocryphal_books + @@books
      else
        @@books
      end
    end

    # assemble the book regex
    def self.book_re_string
      @@book_re_string ||= Bible.books.map(&:regex).join('|')
    end

    # compiled book regular expression
    def self.book_re
      @@book_re ||= Regexp.new(book_re_string, Regexp::IGNORECASE)
    end

    # compiled scripture reference regular expression
    def self.scripture_re
      @@scripture_re ||= Regexp.new(
        sprintf('\b' +
         '(?<BookTitle>%s)' +
         '[\s\.]*' +
         '(?<ChapterNumber>\d{1,3})' +
         '(?:\s*[:\.]\s*' +
         '(?<VerseNumber>\d{1,3})\w?)?' +
         '(?:\s*-\s*' +
           '(?<EndBookTitle>%s)?[\s\.]*' +
           '(?<EndChapterNumber>\d{1,3})?' +
           '(?:\s*[:\.]\s*)?' +
           '(?<EndVerseNumber>\d{1,3})?' +
         ')?', book_re_string, book_re_string), Regexp::IGNORECASE)
    end

    def self.reset_regular_expressions
      @@book_re_string = nil
      @@book_re = nil
      @@scripture_re = nil
    end
  end


  class Book
    NULL = Object.new.freeze
    private_constant :NULL

    TESTAMENTS = {
      apocrypha: 'Apocrypha', #todo fix this name (deuterocanonical instead of apocrypha)
      new_testament: 'New Testament',
      old_testament: 'Old Testament',
    }.freeze
    private_constant :TESTAMENTS

    attr_reader :id # @return [Integer]
    attr_reader :name # @return [String]
    attr_reader :abbreviation # @return [String]
    attr_reader :dbl_code # @return [String]
    attr_reader :regex # @return [String]
    attr_reader :regex_matcher # @return [Regexp]
    attr_reader :chapters # @return [Array<Integer>]
    attr_reader :testament # @return [Symbol]
    attr_reader :testament_name # @return [String]

    # Uses the same Regex pattern to match as we use in {BibleBot::Reference.parse}.
    # So this supports the same book name abbreviations.
    #
    # @param name [String]
    # @return [BibleBot::Book]
    # @example
    #   BibleBot::Book.find_by_name("Genesis")
    def self.find_by_name(name)
      return nil if name.nil? || name.strip == ""
      name = name.tr('’', "'")
      name = I18n.transliterate(name)

      Bible.books.detect { |book| book.name.casecmp?(name) || book.regex_matcher.match?(name) }
    end

    # Find by the DBL Code defined in {BibleBot::Bible}.
    #
    # @param code [String]
    # @return [BibleBot::Book]
    def self.find_by_dbl_code(code)
      return nil if code.nil? || code.empty?

      Bible.books.detect { |book| book.dbl_code == code }
    end

    # Find by the BibleBot::Book ID defined in {BibleBot::Bible}.
    #
    # @param id [Integer]
    # @return [BibleBot::Book]
    def self.find_by_id(id)
      Bible.books.find { |book| book.id == id }
    end

    def initialize(id:, name:, abbreviation:, dbl_code:, regex:, testament:, chapters: [])
      raise "Unknown testament: #{testament.inspect}" unless TESTAMENTS.key?(testament)

      @id = id
      @name = name
      @abbreviation = abbreviation
      @dbl_code = dbl_code
      @regex = regex
      @chapters = chapters
      @testament = testament
      @testament_name = TESTAMENTS[testament]
      @regex_matcher = Regexp.new('\b'+regex+'\b', Regexp::IGNORECASE).freeze
      @chapter_string_ids = nil
      @reference = nil
      @first_verse = nil
      @last_verse = nil
      @next_book = NULL
      @apocryphal = testament == :apocrypha
    end

    # Whether or not the book is one of the original 66
    # @return [Boolean]
    def apocryphal?
      @apocryphal
    end

    # @return [String]
    def formatted_name
      case name
      when 'Psalms' then 'Psalm'
      else name
      end
    end

    # @return String
    # @example
    #  BibleBot::Book.find_by_id(53).string_id
    #  #=> '2_thessalonians'
    def string_id
      name.downcase.gsub(' ', '_')
    end

    # A reference containing the entire book
    # @return [BibleBot::Reference]
    def reference
      @reference ||= Reference.new(start_verse: start_verse, end_verse: end_verse)
    end

    # @return [Array<String>]
    # @example
    #   BibleBot::Book.find_by_id(39).chapter_string_ids
    #   #=> ['malachi-001', 'malachi-002', 'malachi-003', 'malachi-004']
    def chapter_string_ids
      @chapter_string_ids ||= References.new([reference]).chapter_string_ids
    end

    # @return [Array<Integer>]
    def verse_ids
      @verse_ids ||= chapters
      .flat_map.with_index do |verse_count, i|
        chapter_number = i + 1

        1.upto(verse_count).map do |verse_number|
          verse_id(chapter_number:, verse_number:)
        end
      end
    end

    # @return [BibleBot::Verse]
    def start_verse
      @first_verse ||= Verse.from_id(
        verse_id(chapter_number: 1, verse_number: 1)
      )
    end

    # @return [BibleBot::Verse]
    def end_verse
      @last_verse ||= Verse.from_id(
        verse_id(chapter_number: chapters.length, verse_number: chapters.last)
      )
    end

    # @return [BibleBot::Book, nil]
    def next_book
      return @next_book unless @next_book == NULL
      @next_book = Book.find_by_id(id + 1)
    end

    private
    def verse_id(chapter_number:, verse_number:)
      Verse.integer_id(book_id: id, chapter_number:, verse_number:)
    end
  end


  class ReferenceMatch
    attr_reader :match # @return [Match] The Match instance returned from the Regexp
    attr_reader :length # @return [Integer] The length of the match in the text string
    attr_reader :offset # @return [Integer] The starting position of the match in the text string

    # Converts a string into an array of ReferenceMatches.
    # Note: Does not validate References.
    #
    # @param text [String]
    # @return [Array<BibleBot::ReferenceMatch>]
    def self.scan(text)
      # convert en dash & em dash to hyphens
      text = text.tr("\u2013\u2014", '--')

      # convert smart quotes to apostrophes, they cause an "invalid pattern in look-behind" error
      text = text.tr('’', "'")

      # convert non-ASCII characters to their closest English equivalent
      text = I18n.transliterate(text)

      # Compact consecutive spaces into 1.
      # This is necessary for negative lookup matchers, such as the one for "John".
      text.squeeze!(' ')

      scripture_reg = Bible.scripture_re
      Array.new.tap do |matches|
        text.scan(scripture_reg){ matches << self.new($~, $~.offset(0)[0]) }
      end
    end

    # @return [BibleBot::Reference] Note: Reference is not yet validated
    def reference
      @reference ||= Reference.new(
        start_verse: Verse.new(book: start_book, chapter_number: start_chapter.to_i, verse_number: start_verse.to_i),
        end_verse: Verse.new(book: end_book, chapter_number: end_chapter.to_i, verse_number: end_verse.to_i),
      )
    end

    private

    attr_reader :b1 # @return [String]
    attr_reader :c1 # @return [String] Represents the number after the start Book name, could be either chapter or verse number.
    attr_reader :v1 # @return [String, nil] Represents the number after the colon, will always be start_verse if present.
    attr_reader :b2 # @return [String, nil]
    attr_reader :c2 # @return [String, nil] Represents the number after the end Book name, could be either chapter or verse number.
    attr_reader :v2 # @return [String, nil] Represents the number after the colon, will always be end_verse if present.

    # @param match [Match]
    # @param offset [Integer]
    def initialize(match, offset)
      @match = match
      @length = match.to_s.length
      @offset = offset
      @b1 = match[:BookTitle]
      @c1 = match[:ChapterNumber]
      @v1 = match[:VerseNumber]
      @b2 = match[:EndBookTitle]
      @c2 = match[:EndChapterNumber]
      @v2 = match[:EndVerseNumber]
    end

    # @return [BibleBot::Book]
    def start_book
      # There will always be a starting book.
      Book.find_by_name(@b1)
    end

    # @return [BibleBot::Book]
    def end_book
      # The end book is optional. If not provided, default to starting book.
      Book.find_by_name(@b2) || start_book
    end

    # @return [Integer]
    def start_chapter
      c1
    end

    # @return [Integer]
    def start_verse
      # If there is a number in the v1 position, it will always represent the starting verse.
      # There are a few cases where the start_verse will be in a different position or inferred.
      # * Jude 4    (start_verse is in the c1 position)
      # * Genesis 5 (start_verse is inferred to be 1, and end_verse is the last verse in Genesis 5)
      v1 || 1
    end

    # @return [Integer]
    def end_chapter
      return start_chapter if single_verse_ref? # Ex: Genesis 1:3 => "1"
      return c1 if !b2 && !v2 && v1  # Ex: Genesis 1:2-3 => "1"
      c2 ||   # Ex: Genesis 1:1 - 2:4 => "4"
      c1      # Ex: Genesis 5 => "5"
    end

    # @return [Integer]
    def end_verse
      return start_verse if single_verse_ref? # Ex: Genesis 1:3 => "3"
      v2 || # Ex: Genesis 1:4 - 2:5 => "5"
      (
        (v1 && !b2) ?
        c2 : # Ex: Gen 1:4-8  => "8"
        end_book.chapters[end_chapter.to_i - 1] # Genesis 1 => "31"
      )
    end

    # @return [Boolean]
    def single_verse_ref?
      !b2 && !c2 && !v2 && v1
      # Ex: Genesis 5:1 || Jude 5
      # Genesis 5 is not a single verse ref
    end
  end

  class Verse
    include Comparable

    attr_reader :book # @return [BibleBot::Book]
    attr_reader :chapter_number # @return [Integer]
    attr_reader :verse_number # @return [Integer]

    # Turns an Integer into a Verse
    # For more details, see note above the `id` method.
    #
    # @param id [Integer, String]
    # @return [BibleBot::Verse]
    # @example
    #   BibleBot::Verse.from_id(19_105_001) #=> <BibleBot::Verse book="Psalms" chapter_number=105 verse_number=1>
    def self.from_id(id)
      return from_string_id(id) if id.is_a?(String)
      return nil if id.nil?
      raise BibleBot::InvalidVerseError unless id.is_a?(Integer)

      book_id        = id / 1_000_000
      chapter_number = id / 1_000 % 1_000
      verse_number   = id % 1_000
      book           = BibleBot::Book.find_by_id(book_id)

      new(book: book, chapter_number: chapter_number, verse_number: verse_number)
    end

    # @param book_id [Integer]
    # @param chapter_number [Integer]
    # @param verse_number [Integer]
    # @return [Integer]
    def self.integer_id(book_id:, chapter_number:, verse_number:)
      "#{book_id}#{chapter_number.to_s.rjust(3, '0')}#{verse_number.to_s.rjust(3, '0')}".to_i
    end

    # @param book [BibleBot::Book]
    # @param chapter_number [Integer]
    # @param verse_number [Integer]
    def initialize(book:, chapter_number:,  verse_number:)
      @book = book
      @chapter_number = chapter_number
      @verse_number = verse_number
      @id = nil
    end

    # Returns an Integer in the from of
    #
    #   |- book.id
    #   |   |- chapter_number
    #   |   |   |- verse_number
    #   XX_XXX_XXX
    #
    # Storing as an Integer makes it super convenient to store in a database
    # and compare verses and verse ranges using simple database queries
    #
    # @return [Integer]
    # @example
    #   verse.id #=> 19_105_001
    #                 #-> this represents "Psalm 105:1"
    def id
      @id ||= self.class.integer_id(book_id: book.id, chapter_number:, verse_number:)
    end

    # @deprecated Use {id} instead
    # @return [String] ex: "psalms-023-001"
    def string_id
      "#{book.string_id}-#{chapter_number.to_s.rjust(3, '0')}-#{verse_number.to_s.rjust(3, '0')}"
    end

    # The Comparable mixin uses this to define all the other comparable methods
    #
    # @param other [BibleBot::Verse]
    # @return [Integer] Either -1, 0, or 1
    #   * -1: this verse is less than the other verse
    #   * 0: this verse is equal to the other verse
    #   * 1: this verse is greater than the other verse
    def <=>(other)
      id <=> other.id
    end

    # @param include_book [Boolean]
    # @param include_chapter [Boolean]
    # @param include_verse [Boolean]
    # @return [String]
    # @example
    #   verse.formatted #=> "Genesis 5:23"
    def formatted(include_book: true, include_chapter: true, include_verse: true)
      str = String.new # Using String.new because string literals will be frozen in Ruby 3.0
      str << "#{book.formatted_name} " if include_book

      str << "#{chapter_number}" if include_chapter
      str << ":" if include_chapter && include_verse
      str << "#{verse_number}" if include_verse

      str.strip.freeze
    end

    # Returns next verse. It will reach into the next chapter or the next book
    # until it gets to the last verse in the bible,
    # at which point it will return nil.
    #
    # @return [BibleBot::Verse, nil]
    def next_verse
      return Verse.new(book: book, chapter_number: chapter_number, verse_number: verse_number + 1) unless last_verse_in_chapter?
      return Verse.new(book: book, chapter_number: chapter_number + 1, verse_number: 1) unless last_chapter_in_book?
      return Verse.new(book: book.next_book, chapter_number: 1, verse_number: 1) if book.next_book
      nil
    end

    # @return [Boolean]
    def last_verse_in_chapter?
      verse_number == book.chapters[chapter_number - 1]
    end

    # @return [Boolean]
    def last_chapter_in_book?
      chapter_number == book.chapters.length
    end

    # @return [Hash]
    def inspect
      {
        book: book&.name,
        chapter_number: chapter_number,
        verse_number: verse_number
      }
    end

    # @return [Boolean]
    def valid?
      book.is_a?(BibleBot::Book) &&
      chapter_number.is_a?(Integer) && chapter_number >= 1 && chapter_number <= book.chapters.length &&
      verse_number.is_a?(Integer) && verse_number >= 1 && verse_number <= book.chapters[chapter_number-1]
    end

    # Raises error if reference is invalid
    def validate!
      raise InvalidVerseError.new "Verse is not valid: #{inspect}" unless valid?
    end

    private

    # This gets called by {from_id} to allow it to be backwards compatible for a while.
    # @deprecated Use {from_id} instead.
    # @param verse_id [String] ex: "genesis-001-001"
    # @return [BibleBot::Verse] ex: <BibleBot::Verse book="Genesis" chapter_number=1 verse_number=1>
    def self.from_string_id(string_id)
      parts = string_id.split( '-' )

      book_name      = parts[0].gsub( '_', ' ' )
      chapter_number = parts[1].to_i
      verse_number   = parts[2].to_i

      book = BibleBot::Book.find_by_name(book_name)
      new(book: book, chapter_number: chapter_number, verse_number: verse_number)
    end
  end
end
