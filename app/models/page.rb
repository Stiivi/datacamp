# -*- encoding : utf-8 -*-
class Page < ActiveRecord::Base
  set_primary_key :id
  translates :body, :title, :block
  locale_accessor I18N_LOCALES

  has_many :blocks

  def html_body
    RedCloth.new(self.body || "").to_html
  end

  def to_param
    page_name
  end

  def get_sorted_blocks
    blocks.find :all, :order => "name"
  end
end
