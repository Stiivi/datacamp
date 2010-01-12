########################################################################
# Installation of localized static pages

require 'pathname'

locales_path = Pathname "config/locales"
puts "=> Creating static pages "

locales_path.children.each { | locale_dir |

    if locale_dir.extname != ".locale"
        next
    end

    locale_name = locale_dir.basename.to_s.gsub(/\..*/, "")

    puts "-- locale: #{locale_name} "

    pages_dir = locale_dir + "pages"
    titles_file = pages_dir + "titles.yml"
    if titles_file.exist?
        titles = YAML.load_file(pages_dir + "titles.yml")
    else
        titles = { }
    end
    
    I18n.locale = locale_name.to_sym
    pages_dir.children.each { | page_file |
        page_name = page_file.basename.to_s.gsub(/\..*/, "")

        if page_file.extname != ".txt"
            next
        end

        page = Page.find_by_page_name(page_name)

        if page.nil?
            page = Page.new
            page.page_name = page_name
        end
        page.title = titles[page_name]
        puts "---- page #{page.title} (#{page_name})"

        page.body = File.read(page_file)
        page.save
    }
    
}


