module Settings
  class ApplicationController < ::ApplicationController
    private
      def init_menu
        @submenu_partial = "settings"
      end
  end
end
