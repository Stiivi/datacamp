module Settings
  class SystemVariablesController < ApplicationController
    privilege_required :edit_system_settings

    def index
      @system_variables = SystemVariable.all
    end

    def update_all
      system_variables = params[:system_variables]
      system_variables.each do |id, system_variable|
        system_var = SystemVariable.find_by_id(id.to_i)
        system_var.update_attributes(system_variable)
      end

      redirect_to settings_system_variables_path
    end
  end
end
