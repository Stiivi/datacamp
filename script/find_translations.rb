# -*- encoding : utf-8 -*-
#!/usr/bin/ruby
# 
# Find all translateable strings in Views
#
#

# pouzivat globalne cesy
# abstrakcia pred strukturou aplikacie
# 

require 'pathname'


SEARCH_PATH = "app"
EXTENSIONS = [".haml", ".rb"]


def find_files(path)
    files = Array.new
    
    path.children.each { |child|
        if child.directory?
            files = files + find_files(child)
        else
            files.push child if EXTENSIONS.include? child.extname
        end
    }

    return files
end

def find_strings(file_name)
    array = Array.new
    
    begin
    
    file = File.new(file_name)

    if file_name.to_s =~ /views/
        view = file_name.to_s.gsub(/.*views\//,"").gsub(/\/.*/,"")
    end
    linenum = 0
    while (line = file.readline)
        linenum = linenum + 1
        strings1 = line.scan(/t\("[^"]*\"/)
        strings1 = strings1.collect { | str | 
                str.gsub(/t\("/,"").gsub(/"$/,"")
            }

        strings2 = line.scan(/t +"[^"]*\"/)
        strings2 = strings2.collect { | str | 
                str.gsub(/t +"/,"").gsub(/"$/,"")
            }

        strings = strings1 + strings2
        
        strings.each { |string|
            if view 
                if string =~ /^\./
                    fixed_string = view + string
                else
                    fixed_string = view + "." + string
                end
            else 
                fixed_string = string
            end
            puts "#{string}\t#{fixed_string}\t#{file_name}\t#{linenum}"
        }
        #    array << line
        # end
    end

    rescue EOFError
        file.close
    end

    return array
end

def main
    path = Pathname.new(SEARCH_PATH)
    
    files = find_files(path)
    
    strings = Array.new
    files.each { |file|
        strings = strings & find_strings(file)
    }
        
    puts strings
end

main

