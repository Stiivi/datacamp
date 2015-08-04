namespace :ts do
  desc "Run Sphinx in the foreground"
  task :start_in_foreground => ['ts:stop'] do
    config = ThinkingSphinx::Configuration.instance
    controller = config.controller

    unless pid = fork
      exec "#{controller.bin_path}#{controller.searchd_binary_name} --pidfile --config #{config.configuration_file} --nodetach"
    end

    Signal.trap('TERM') { Process.kill('TERM', pid) }
    Signal.trap('INT')  { Process.kill('INT', pid) }
    Process.wait(pid)
  end

  desc "Ensure Sphinx is running"
  task :ensure_running do
    config = ThinkingSphinx::Configuration.instance
    controller = config.controller

    if controller.running?
      puts "Sphinx is already running"
    else
      puts "Starting Sphinx"
      Rake::Task["ts:configure"].invoke
      Rake::Task["ts:index"].invoke
      Rake::Task["ts:start"].invoke
    end
  end
end
