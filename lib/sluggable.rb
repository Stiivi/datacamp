module Sluggable
  def self.included(base)
    base.class_eval do
      before_save :save_slug
    end
  end
  
  def to_param
    slug || id.to_s
  end
  
  def save_slug
    begin
      self.slug = (title.gsub(/[^a-zA-Z1-9]/, ' ').gsub(/\s+/, '-').downcase)
    rescue
      self.slug = self.id
    end
    
    # Check if there already is item with this slug
    n = 1
    temp_slug = self.slug
    while self.class.find_by_slug(temp_slug, :conditions => ["id <> ?", self.id]) do
      temp_slug = self.slug + "-#{n}"
      n += 1
    end
    self.slug = temp_slug
  end
end