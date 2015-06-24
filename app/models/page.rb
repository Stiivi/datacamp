# -*- encoding : utf-8 -*-
class Page < ActiveRecord::Base

  translates :body, :title, :block
  locale_accessor I18N_LOCALES

  has_many :blocks

  validates :page_name, presence: true, allow_blank: false

  def html_body
    RedCloth.new(self.body || "").to_html
  end

  def to_param
    page_name
  end

  def get_sorted_blocks
    blocks.order("name")
  end
end
