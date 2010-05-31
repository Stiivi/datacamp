class Page < ActiveRecord::Base
    translates :body, :title
    locale_accessor I18N_LOCALES
    
    def html_body
        doc = RedCloth.new(self.body || "")
        return doc.to_html
    end
    
    def to_param
      page_name
    end
    
    def self.find_by_page_name(page_name)
      @pages ||= Page.find :all, :include => :translations
      @pages.find_all{|page|page.page_name == page_name}.first
    end
end
