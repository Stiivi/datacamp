# -*- encoding : utf-8 -*-
#!/usr/bin/ruby
# 
# Find untranslated strings
#
# English locale is taken as reference. For each locale in config/locales
# a file with missing translations from english is created:
#     config/locales/XX.locale/strings_untranslated.yml
#

require 'pathname'
require 'yaml'
require 'csv'
require 'rubygems'
require 'ya2yaml'

$KCODE = "UTF8"

class LocaleComparator
def compare_locale(left_locale, right_locale)
    diff = Hash.new
    if not right_locale
        return nil
    end
    
    left_locale.keys.each { |domain|
        # puts "--- comparing domain #{domain}"
        if not right_locale.has_key?(domain)
            diff[domain] = left_locale[domain]
            diff[domain]["FIXME"] = "UNTRANSLATED new domain"
        else
            domain_diff = compare_domain(left_locale[domain], right_locale[domain])
            diff[domain] = domain_diff if not domain_diff.empty?
        end
    }
    
    return diff
end

def compare_domain(left_domain, right_domain)
    diff = Hash.new
    left_domain.keys.each { |key|
        if right_domain.has_key?(key) and not right_domain[key] =~ /^TRANSLATE: /
            diff[key] = right_domain[key]
        else
            diff[key] = "TRANSLATE: #{left_domain[key]}"
        end
    }
    return diff
end

def compare_locale_file(locale_file_name)
    puts "==> Comparing #{locale_file_name}"
    main_yaml = YAML.load_file(@locales_path + "#{@main_locale_name}.locale" + locale_file_name)
    
    main_locale = main_yaml[@main_locale_name]
    
    @locales.each { |locale_name|
        target_file = @locales_path + "#{locale_name}.locale" + locale_file_name
        if not target_file.exist?
            puts "--! NO TRANSLATION file #{locale_file_name} to compare"
            next
        end
        yaml = YAML.load_file(target_file)
        locale = yaml[locale_name]
        
        # compare locales
        diff = compare_locale(main_locale, locale)
        diff_out = Hash.new
        diff_out[locale_name] = diff
        if not diff
            puts "--! NIL DIFF"
        end
        locale_file = locale_file_name.basename.to_s.gsub(/\.[^.]*$/, "")
        filename = @locales_path + "#{locale_name}.locale/#{locale_file}_untranslated.yml"
        puts "==> Generating diff #{filename}"
        File.open( filename, 'w' ) do |out|
            out.write diff_out.ya2yaml
        end
    }
end


def run
    @locales_path = Pathname.new("config/locales")
    
    puts "==> Comparing translations"
    
    @locales = @locales_path.children.select { | path | path.directory? and path.extname == ".locale"}
    @locales = @locales.collect { |path| path.basename.to_s.gsub(/\.[^.]*$/, "")}
    
    @main_locale_name = "en"
    # remove main locale
    @locales.delete(@main_locale_name)
    puts "--- main locale       : #{@main_locale_name}"
    puts "--- locales to compare: #{@locales.join(', ')}"

    main_path = @locales_path + "#{@main_locale_name}.locale"
    files = main_path.children.select { |file| file.extname == ".yml" }
    files.each { |file|
        compare_locale_file(file.basename)
    }
    
end
end

tool = LocaleComparator.new
tool.run
