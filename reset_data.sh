echo 'rake db:drop'
bundle exec rake db:drop

echo 'rake db:create'
bundle exec rake db:create

echo 'rake db:migrate'
bundle exec rake db:migrate

echo 'rails runner db/seeds.rb'
bundle exec rails runner db/seeds.rb

echo 'ruby db/workflow_def/workflow_seed.rb'
ruby db/workflow_def/workflow_seed.rb
