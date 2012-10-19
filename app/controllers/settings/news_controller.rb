module Settings
  class NewsController < ApplicationController
    privilege_required :data_editor
    respond_to :html

    def index
      @news = News.all
      respond_with @news
    end

    def new
      @news_item = News.new
      respond_with @news
    end

    def create
      @news_item = News.create(params[:news])
      respond_with @news_item, location: settings_news_index_path
    end

    def edit
      @news_item = News.find(params[:id])
      respond_with @news_item
    end

    def update
      @news_item = News.find(params[:id])
      @news_item.update_attributes(params[:news])
      respond_with @news_item, location: settings_news_index_path
    end
  end
end
