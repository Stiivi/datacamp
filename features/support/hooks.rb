After('@cleanup_files_after') do
  Dir.glob("#{Rails.root}/files/*_test.csv").each do |filepath|
    File.delete(filepath)
  end
end