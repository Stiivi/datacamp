# -*- encoding : utf-8 -*-

module Etl
  module Shared
    module VvoIncludes

      # private

      def update_report_object(type, key, value)
        data = config.reload.last_run_report[type]
        data[key] = value
        config.update_report!(type, data)
      end

      def update_report_object_depth_2(type1, type2, key, value)
        data = config.reload.last_run_report[type1][type2]
        data[key] = value
        res = config.last_run_report[type1]
        res[type2.to_sym] = data
        config.update_report!(type1, res)
      end

    end
  end
end
