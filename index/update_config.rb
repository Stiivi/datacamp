puts "Updating config from Datacamp"

database_name = Rails.env+"_data"
config = YAML.load_file(File.join(Rails.root, "config", "database.yml"))[database_name]

global_config = ""
global_config += "type = #{config["adapter"] == 'mysql2' ? 'mysql' : config["adapter"]}\n" if config["adapter"]
global_config += "sql_host = #{config["host"]||"localhost"}\n"
global_config += "sql_port = #{config["port"]}\n" if config["post"]
global_config += "sql_user = #{config["username"]}\n" if config["username"]
global_config += "sql_pass = #{config["password"]}\n"
global_config += "sql_db = #{config["database"]}\n"
global_config += "sql_query_pre = SET NAMES utf8\n"

all_config = "
searchd {
  listen = localhost:9312
  pid_file = #{Rails.root}/tmp/pids/search.pid
  log = #{Rails.root}/log/search.log
}
"

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
  dataset_config += "charset_type = utf-8\n"
  dataset_config += "charset_table = 0..9, A..Z->a..z, _, a..z, U+0e1->a, U+0c1->a, U+0e4->a, U+0c4->a, U+10d->c, U+10c->c, U+10f->d, U+10e->d, U+0e9->e, U+0c9->e, U+0ed->i, U+0cd->i, U+13e->l, U+13d->l, U+13a->l, U+139->l, U+148->n, U+147->n, U+0f3->o, U+0d3->o, U+0f4->o, U+0d4->o, U+155->r, U+154->r, U+161->s, U+160->s, U+165->t, U+164->t, U+0fa->u, U+0da->u, U+0fd->y, U+0dd->y, U+17e->z, U+17d->z\n"
  dataset_config += "\n}\n"
  
  all_config += dataset_config
end

config_file_path = File.join(Rails.root, "index", "sphinx.conf")
File.open(config_file_path, "w").write(all_config)
puts "Saved #{config_file_path}"
