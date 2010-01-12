puts "=> Installing data formats ..."
data_formats = [
  {:name => "default",
   :value => ''
  },
  {:name => "number",
   :value => "%d"
  },
  {:name => "currency",
   :value => "%f &euro;"
  },
  {:name => "percentage",
   :value => "%f &euro;"
  },
  {:name => "bytes",
   :value => "%f &euro;"
  },
  {:name => "date",
   :value => "%f &euro;"
  },
  {:name => "text",
   :value => "%s"
  },
  {:name => "url",
   :value => '<a href="%s">%s</a>'
  },
  {:name => "email",
   :value => '<a href="mailto:%s">%s</a>'
  },
  {:name => "flag",
   :value => '%s'
  }
]

data_formats.each do |format|
  format_obj = DataFormat.find_or_create_by_name(format[:name])
  format_obj.update_attributes(format)
end