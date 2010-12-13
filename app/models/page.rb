# -*- encoding : utf-8 -*-
class Page < ActiveRecord::Base
    translates :body, :title
    locale_accessor I18N_LOCALES
    
    has_many :blocks
    
    def html_body
        doc = RedCloth.new(self.body || "")
        return doc.to_html
    end
    
    def to_param
      page_name
    end
    
    def get_sorted_blocks
      results = self.blocks.find :all, :order => "name"
    end
    
    def self.find_by_page_name(page_name)
      @pages ||= Page.find :all, :include => :translations
      @pages.find_all{|page|page.page_name == page_name}.first
    end
end
