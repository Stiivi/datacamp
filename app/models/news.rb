class News < ActiveRecord::Base
  translates :title, :text
  locale_accessor I18N_LOCALES

  default_scope order('created_at desc')

  def self.published
    where(published: true)
  end
end
