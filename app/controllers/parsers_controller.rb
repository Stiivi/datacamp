class ParsersController < ApplicationController
  privilege_required :data_editor
  def index
    @parsers = EtlConfiguration.parsers
  end

  def show
    @parser = EtlConfiguration.find(params[:id])
  end

  def run
    @parser = EtlConfiguration.find(params[:id])
    if @parser.valid_for_parsing?(params[:settings])
      "Parsers::#{@parser.name.classify}::Downloader".constantize.new(@parser.id, params[:settings][:year]).delay.perform
      redirect_to parsers_path, notice: t('parsers.run.success')
    else
      render :show
    end
  end

  def download
    parser = EtlConfiguration.find(params[:id])
    download_location = Parsers::Support.get_path(parser.download_path, bucketize: false)
    file = Pathname(download_location)
    if file.exist?
      send_file file, type: "text/csv; charset=utf-8", disposition: 'inline', x_sendfile: false
    else
      error :object_not_found, message: "There is no parsed data available!"
    end
  end

  private
    def init_menu
      @submenu_partial = 'data_dictionary'
    end
end
