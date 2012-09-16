namespace :migrate_data do
  task field_description_categories: :environment do
    FieldDescription.all.each do |field_description|
      field_description_translations = field_description.translations.select{|fdt| fdt.category.present?}
      field_description_categories = FieldDescriptionCategory.
          includes(:translations).
          where(field_description_category_translations: {title: field_description_translations.map(&:category),
                                                          locale: field_description_translations.map(&:locale)})


      field_description_category =  if field_description_categories.present?
                                      fdc = field_description_categories.first

                                      field_description_translations.each do |fdt|
                                        if fdc.translations.select{|fdc| fdc.locale == fdt.locale}.blank?
                                          fdc.translations.create!(locale: fdt.locale, title: fdt.category)
                                        end
                                      end

                                      fdc
                                    else
                                      fdc = FieldDescriptionCategory.create!

                                      field_description_translations.each do |fdt|
                                        fdc.translations.build(locale: fdt.locale, title: fdt.category)
                                      end

                                      fdc.save!
                                      fdc
                                    end

      unless field_description_category.dataset_descriptions.include?(field_description.dataset_description)
        field_description_category.dataset_descriptions << field_description.dataset_description
      end

      field_description.field_description_category = field_description_category
      field_description.save!
    end
  end
end
