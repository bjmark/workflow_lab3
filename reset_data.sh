echo 'rake db:drop'
bundle exec rake db:drop

echo 'rake db:create'
bundle exec rake db:create

echo 'rake db:migrate'
bundle exec rake db:migrate

echo 'rails runner db/seeds.rb'
bundle exec rails runner db/seeds.rb

echo 'rake blade:workflow_seed'
bundle exec rake blade:workflow_seed
