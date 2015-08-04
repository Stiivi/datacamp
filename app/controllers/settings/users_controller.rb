require 'csv'

module Settings
  class UsersController < ApplicationController
    before_filter :login_required, :except => [:restore]
    privilege_required :manage_users, :except => [:new, :restore]

    def index
      @filters = params[:filters] || {}
      active_filters = @filters.find_all do |field, value|
        %q{login name email api_access_level}.include?(field) &&
        value.present?
      end
      conditions_sql = active_filters.collect{|f,v|"#{f} LIKE ?"}.join(" AND ")
      conditions_values = active_filters.collect{|f,v|"%#{v}%"}

      respond_to do |wants|
        wants.html {
          paginate_options = {:page => params[:page]||1, :per_page => 20}
          select_options = {:conditions => [conditions_sql, *conditions_values]}
          @users = User.paginate paginate_options.merge(select_options)
        }
        wants.csv {
          @users = User.all
          render :text => collection_as_csv(@users, [:login, :name, :email])
        }
      end
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(params[:user])
      success = @user && @user.save(validate: false)
      if success
        redirect_to settings_users_path
      else
        render :action => 'new'
      end
    end

    def destroy
      @user = User.find_by_id params[:id]
      @user.destroy
      redirect_to settings_users_path
    end

    def edit
      @user = User.find_by_id params[:id]
    end

    def update
      @user = User.find_by_id params[:id]

      @user.attributes = params[:user]
      @user.access_right_ids = params[:user][:access_right_ids]
      @user.access_role_ids = params[:user][:access_role_ids]

      if @user.save(validate: false)
        redirect_to edit_settings_user_path(@user)
      else
        render :action => "edit"
      end
    end

    def restore
      @account = User.find_by_restoration_code(params[:id] || ".")
      if request.put?
        user = params[:user]
        if user[:password].present? && user[:password] == user[:password_confirmation]
          @account.password = user[:password]
          @account.restoration_code = nil
          @account.save(validate: false)
          redirect_to login_path, notice: t('users.password_restored')
        else
          flash.now[:error] = t('users.password_invalid')
        end
      end
    end

    def dashboard
      @user = current_user
    end

    protected

    # FIXME: Make this reusable
    def collection_as_csv(collection, fields)
      output = ""
      output << CSV.generate_line(fields)
      output << "\n"
      collection.each do |item|
        values = fields.collect do |field|
          item.send(field)
        end
        output << CSV.generate_line(values)
        output << "\n" unless item == collection.last
      end
      output
    end
  end
end
