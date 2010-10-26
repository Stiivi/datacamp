# Accounts Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Sep 2009
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class AccountsController < ApplicationController
  before_filter :login_required, :except => [:forgot, :restore, :new, :create]
  before_filter :get_account, :only => [:show, :password, :update]
  
  def show
  end
  
  ############################################################
  # Action for only changing user's password
  def password
  end
  
  def update
    # raise params[:user].to_yaml
    @account.attributes = params[:user]
    # raise @account.to_yaml
    if @account.save
      if params[:redirect]
        redirect_to params[:redirect]
      else
        redirect_to account_path
      end
    else
      render :action => "show"
    end
  end
  
  def forgot
    if request.method == :post
      @account = User.find_by_email(params[:user][:email])
      unless @account
        flash[:error] = I18n.t("global.user_not_found")
        return redirect_to forgot_account_path
      end
      @account.create_restoration_code
      @account.save(false)
      UserMailer.deliver_forgot_password(@account)
      flash[:notice] = I18n.t("global.email_sent")
      redirect_to forgot_account_path
    end
  end
  
  ############################################################
  # Registration
  
  def new
    @account = User.new
  end
  
  def create
    @account = User.new
    @account.api_access_level = Api::REGULAR
    %w{login email password password_confirmation accepts_terms}.each do |param|
      @account.send "#{param}=", params[:user][param.to_sym]
    end
    if @account.valid? && verify_captcha_for(@account)
      @account.save
      self.current_user = @account
      flash[:notice] = t("users.registration_complete")
      redirect_to root_path
    else
      render :action => "new"
    end
  end
  
  private
  
  def get_account
    @account = current_user
    @comments = Comment.find_include_suspended :all, :conditions => {:user_id => current_user.id}
    @favorites = @account.favorites || []
    # FIXME: This might get slow with many favorites. Favorites tab should be loaded
    # with Ajax after clicking it.
  end
end
