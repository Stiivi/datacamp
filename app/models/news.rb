class News < ActiveRecord::Base
  translates :title, :text
  locale_accessor I18N_LOCALES

  default_scope order(:updated_at)

  def self.published
    where(published: true)
  end
end
