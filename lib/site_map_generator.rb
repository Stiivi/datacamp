# -*- encoding : utf-8 -*-

class SiteMapGenerator

  LOCALES = {sk: '', en: 'en'}
  ROOT_URL = 'http://datanest.fair-play.sk'
  LIMIT_URLS = 50000
  PER_PAGE = 10

  # first run generator
  def self.generate_all_files
    Dir.mkdir(sitemaps_dir) unless File.exists?(sitemaps_dir)
    LOCALES.each_pair do |locale, locale_path|
      generator = Generator.new(locale, locale_path)
      generator.delay.generate
    end
  end

  # last run generate xml file
  def self.create_site_map
    f = File.open(self.site_map_file, "wb:UTF-8")
    str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    file_names = []
    self.find_site_maps_files.each do |file_path|
      file_names << File.basename(file_path, ".txt")
    end
    file_names = file_names.sort
    file_names.each do |file_name|
      str+= "\t<sitemap>\n\t\t<loc>#{ROOT_URL}/sitemaps/#{file_name}.txt</loc>\n\t</sitemap>\n"
    end
    str+= "</sitemapindex>\n"
    f.write(str)
    f.close
  end

  private

    def self.find_site_maps_files
      file_path = Rails.root.join 'public', 'sitemaps', '*.txt'
      Dir.glob(file_path)
    end

    def self.site_map_file
      Rails.root.join 'public', 'sitemap.xml'
    end

    def self.sitemaps_dir
      Rails.root.join 'public', 'sitemaps'
    end

  class Generator

    attr_reader :locale, :locale_path

    def initialize(locale, locale_path)
      @locale = locale
      @locale_path = locale_path
    end

    def generate
      # static pages
      delay.generate_static_pages
      # searches
      delay.generate_searches
      # datasets
      delay.generate_datasets
    end

    # static pages --------

    def generate_static_pages
      # init file
      f = init_site_map_file('static')
      generate_pages(f)
      generate_news(f)
      # close file
      f.close
    end

    def generate_pages(f)
      Page.all.each do |page|
        add_url f, page_path(page)
      end
    end

    def generate_news(f)
      add_url f, new_path
      News.published.each do |new|
        add_url f, new_path(new)
      end
    end

    # searches ---------

    def generate_searches
      f_index = 1
      f = init_site_map_file("searches-#{f_index}")
      count = 0
      Search.find_each do |search|
        add_url f, search_path(search)
        count+= 1
        if count == LIMIT_URLS
          f.close
          f_index+= 1
          count = 0
          f = init_site_map_file("searches-#{f_index}")
        end
      end
      f.close
    end

    def generate_datasets
      DatasetDescription.where(is_active: true).each do |dataset_description|
        dataset = dataset_description.dataset_record_class
        delay.generate_dataset(dataset_description, dataset)
      end
    end

    def generate_dataset(dataset_description, dataset)
      count_records = dataset.active.count
      count_pages = (count_records / PER_PAGE) + (count_records % PER_PAGE == 0 ? 0 : 1)
      f_index = 1
      f = init_site_map_file(dataset_site_map_file(dataset_description, f_index))
      add_url f, dataset_path(dataset_description)
      count = 1
      for page in 2..count_pages do
        add_url f, dataset_path(dataset_description, page)
        count+= 1
        if count == LIMIT_URLS
          f.close
          f_index+= 1
          count = 0
          f = init_site_map_file(dataset_site_map_file(dataset_description, f_index))
        end
      end
      f.close

      delay.generate_records(dataset_description, dataset)
    end

    def generate_records(dataset_description, dataset)
      count_records = dataset.active.count
      count_pages = (count_records / LIMIT_URLS) + (count_records % LIMIT_URLS == 0 ? 0 : 1)
      for index in 1..count_pages do
        delay.create_dataset_records_file(dataset_description, dataset, index)
      end
    end

    def create_dataset_records_file(dataset_description, dataset, index)
      f = init_site_map_file(dataset_records_site_map_file(dataset_description, index))
      limit = LIMIT_URLS
      offset = LIMIT_URLS * (index-1)
      dataset.active.offset(offset).limit(limit).order(:_record_id).each do |record|
        add_url f, record_path(dataset_description, record)
      end
      f.close
    end

    private

    def new_path(new = nil)
      if new
        "news/#{new.id}"
      else
        "news"
      end
    end

    def dataset_path(dataset_description = nil, page = nil)
      if dataset_description
        if page
          "datasets/#{dataset_description.id}?page=#{page}"
        else
          "datasets/#{dataset_description.id}"
        end
      else
        'datasets'
      end
    end

    def dataset_site_map_file(dataset_description, index)
      "dataset-#{dataset_description.id}-#{index}"
    end

    def dataset_records_site_map_file(dataset_description, index)
      "dataset-#{dataset_description.id}-records-#{index}"
    end

    def record_path(dataset_description, record)
      "datasets/#{dataset_description.id}/records/#{record.id}"
    end

    def page_path(page)
      "pages/#{page.page_name}"
    end

    def search_path(search)
      "searches/#{search.id}"
    end

    def add_url(f, path)
      f.write url_for(path)
      f.write "\n"
    end

    def  init_site_map_file(file)
      File.open(site_map_urls_file(file), 'wb:UTF-8')
    end

    def url_for(path)
      l = locale_path.blank? ? '' : "#{locale_path}/"
      "#{ROOT_URL}/#{l}#{path}"
    end

    def site_map_urls_file(file_name)
      file_path = "sitemap-#{locale}-#{file_name}.txt"
      Rails.root.join 'public', 'sitemaps', file_path
    end
  end

end
