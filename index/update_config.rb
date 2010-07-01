puts "Updating config from Datacamp"

database_name = Rails.env+"_data"
config = YAML.load_file(File.join(Rails.root, "config", "database.yml"))[database_name]

global_config = ""
global_config += "type = #{config["adapter"]}\n" if config["adapter"]
global_config += "sql_host = #{config["host"]}\n" if config["host"]
global_config += "sql_port = #{config["port"]}\n" if config["post"]
global_config += "sql_user = #{config["username"]}\n" if config["username"]
global_config += "sql_pass = #{config["password"]}\n"
global_config += "sql_db = #{config["database"]}\n"
global_config += "sql_query_pre = SET NAMES utf8\n"

all_config = <<-HERE
searchd {
listen = localhost:9312
pid_file = /var/run/searchd.pid
}
HERE

datasets = DatasetDescription.all

datasets.each do |dataset|
  # Source config
  dataset_config = "source source_#{dataset.identifier}\n{\n"
  dataset_config += global_config
  fields_to_select = ["_record_id"]
  dataset.visible_field_descriptions(:search).each do |field|
    fields_to_select << field.identifier
  end
  sql_query = "SELECT #{fields_to_select.join(", ")} FROM ds_#{dataset.identifier}"
  dataset_config += "sql_query = #{sql_query}"
  
  dataset_config += "\n}\n"

  # Index config
  dataset_config += "index index_#{dataset.identifier}\n{\n"
  dataset_config += "source = source_#{dataset.identifier}\n"
  index_path = File.join(Rails.root, "index", "data", dataset.identifier)
  dataset_config += "path = #{index_path}\n"
  dataset_config += "charset_type = utf-8"
  dataset_config += "\n}\n"
  
  all_config += dataset_config
end

config_file_path = File.join(Rails.root, "index", "sphinx.conf")
File.open(config_file_path, "w").write(all_config)
puts "Saved #{config_file_path}"