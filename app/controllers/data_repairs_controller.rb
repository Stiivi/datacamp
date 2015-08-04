class DataRepairsController < ApplicationController
  privilege_required :data_editor
  respond_to :html, :xml
  def index
    @data_repairs = DataRepair.all
    respond_with @data_repairs
  end

  def show
    @data_repair = DataRepair.find(params[:id])
    begin
      @data = get_preview_data(@data_repair)
    rescue
      @data = []
    end if @data_repair.status == 'starting'
    if @data_repair.status == 'done'
      model_class = DatasetDescription.find_by_identifier(@data_repair.target_table_name).dataset_model
      @data = model_class.select("#{model_class.table_name}.#{@data_repair.target_ico_column} as ico, #{model_class.table_name}.#{@data_repair.target_company_name_column} as company_name, #{model_class.table_name}.#{@data_repair.target_company_address_column} as company_address").where(:_record_id => @data_repair.record_ids) if @data_repair.status == 'done'
    end
    respond_with @data_repair
  end

  def new
    @data_repair = DataRepair.new
    respond_with @data_repair
  end

  def create
    @data_repair = DataRepair.new(params[:data_repair])
    @data_repair.repair_type = 'regis' 
    @data_repair.status = 'starting'
    @data_repair.regis_table_name = DatasetDescription.find_by_id(params[:data_repair][:regis_table_name]).identifier
    @data_repair.target_table_name = DatasetDescription.find_by_id(params[:data_repair][:target_table_name]).identifier
    @data_repair.repaired_records = 0
    records_to_repair = get_preview_data(@data_repair)
    @data_repair.records_to_repair = records_to_repair.length rescue 0
    @data_repair.record_ids = records_to_repair.map(&:target_record_id)
    @data_repair.save
    respond_with @data_repair, :location => location
  end
  
  def update_columns
    record_class = DatasetDescription.find_by_id(params[:id]).dataset_model
    render :json => record_class.columns.map(&:name).to_json, :layout => false
  end
  
  def update_columns_names
    render :json => DatasetDescription.find_by_id(params[:id]).field_descriptions.map{|rc| [rc.id, rc.title]}.to_json, :layout => false
  end
  
  def start_repair
    @data_repair = DataRepair.find(params[:data_repair_id])
    @data_repair.update_attribute(:status, 'in_progress')
    @data_repair.delay.run_data_repair
    redirect_to @data_repair
  end
  
  def sphinx_reindex
    DataRepair.delay.sphinx_reindex
    redirect_to data_repairs_url, :notice => 'Sphinx reindex has started. Please wait a few minuts to let it finish.'
  end
  
  private
  def init_menu
    @submenu_partial = "data_dictionary"
  end
  
  def get_preview_data(data_repair)
    regis_model = DatasetDescription.find_by_identifier(data_repair.regis_table_name).dataset_model
    target_model = DatasetDescription.find_by_identifier(data_repair.target_table_name).dataset_model
    target_model.find_by_sql("SELECT #{target_model.table_name}._record_id as target_record_id,#{target_model.table_name}.#{data_repair.target_ico_column} as ico, #{target_model.table_name}.#{data_repair.target_company_name_column} as company_name, #{target_model.table_name}.#{data_repair.target_company_address_column} as company_address, #{regis_model.table_name}.#{data_repair.regis_ico_column} as matched_ico, #{regis_model.table_name}.#{data_repair.regis_name_column} as matched_company_name, #{regis_model.table_name}.#{data_repair.regis_address_column} as matched_company_address FROM #{target_model.table_name} JOIN #{regis_model.table_name} ON #{regis_model.table_name}.#{data_repair.regis_ico_column} = #{target_model.table_name}.#{data_repair.target_ico_column} WHERE #{target_model.table_name}.#{data_repair.target_company_name_column} IS NULL OR #{target_model.table_name}.#{data_repair.target_company_address_column} IS NULL")
  end
end
