# -*- encoding : utf-8 -*-
require File.join(Rails.root, "lib", "api", "accessable.rb")


class ERB
  module Util
    # see https://github.com/rails/rails/issues/7430 for details
    #
    # A utility method for escaping HTML tag characters.
    # This method is also aliased as <tt>h</tt>.
    #
    # In your ERB templates, use this method to escape any unsafe content. For example:
    # <%=h @person.name %>
    #
    # ==== Example:
    # puts html_escape("is a > 0 & a < 10?")
    # # => is a &gt; 0 &amp; a &lt; 10?
    def html_escape(s)
      s = s.to_s
      if s.html_safe?
        s
      else
        s.gsub(/[&"'><]/, HTML_ESCAPE).html_safe
      end
    end

    alias h html_escape

    singleton_class.send(:remove_method, :html_escape)
    module_function :html_escape, :h
  end
end
