# -*- encoding : utf-8 -*-
module Settings
  class PagesController < ApplicationController
    before_filter :login_required
    privilege_required :edit_pages
    def index
      @pages = Page.all
    end

    def new
      @page = Page.new
    end

    def create
      @page = Page.new(params[:page])
      if @page.save
        redirect_to settings_pages_path
      else
        render :action => "new"
      end
    end

    def show
      redirect_to edit_settings_page_path(params[:id])
    end

    def edit
      @page = Page.find_by_page_name!(params[:id])
    end

    def update
      @page = Page.find_by_page_name(params[:id])
      if @page.update_attributes(params[:page])
        redirect_to settings_pages_path
      else
        render :action => "edit"
      end
    end
  end
end
