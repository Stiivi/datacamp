I18N_LOCALES = [:sk, :en]
I18N_LOCALE_NAMES = {:sk => "Slovensky", :en => "English"}
RECORDS_PER_PAGE = 10
RECORDS_PER_PAGE_OPTIONS = [10, 20, 50, 100, 200]

CSV_TEMPLATES = [
  {
    :id => "csv",
    :title => "CSV",
    :column_separator => ",",
    :number_of_header_lines => 1
  },
  {
    :id => "csv_extended_header",
    :title => "CSV with extended header",
    :column_separator => ",",
    :number_of_header_lines => 2
  }
]

IMPORT_ENCODINGS = [
  ['UTF-8', ''],
  ['Eastern European, MS Windows', 'CP1250'],
  ['Western European, MS Windows', 'CP1251']
]