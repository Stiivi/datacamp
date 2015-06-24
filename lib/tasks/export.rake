# -*- encoding : utf-8 -*-
namespace :db do
  task export: :environment do
    Datanest::Exporter.new.export
  end
end
