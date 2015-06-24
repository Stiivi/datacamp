# -*- encoding : utf-8 -*-
#!/usr/bin/ruby
# 
# fix YAML of locale strings - convert to UTF8
#
# Note: this tool requires ya2yaml gem
#

require 'pathname'
require 'yaml'
require 'csv'
require 'rubygems'
require 'ya2yaml'

$KCODE = "UTF8"


def main
    locales_path = Pathname.new("config/locales")
    
    puts "=> Fixing locale encodings"
    
    locales = locales_path.children.select { | path | path.directory? and path.extname == ".locale"}
    locales = locales.collect { |path| path.basename.to_s.gsub(/\.[^.]*$/, "")}
    
    strings_file = "strings.yml"
    
    locales.each { |locale_name|
        puts "-> fixing #{locale_name}"

        path = locales_path + "#{locale_name}.locale" + strings_file
        yaml = YAML.load_file(path)

        File.open( path, 'w' ) do |out|
            out.write yaml.ya2yaml
        end
    }
end

main
