load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

# Uncomment if you are using Rails' asset pipeline
load 'deploy/assets'

load 'config/deploy' # remove this line to skip loading any of the default tasks
