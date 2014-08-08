echo 'rake db:drop'
rake db:drop

echo 'rake db:create'
rake db:create

echo 'rake db:migrate'
rake db:migrate

echo 'rails runner db/seeds.rb'
rails runner db/seeds.rb

echo 'ruby db/workflow_def/workflow_seed.rb'
ruby db/workflow_def/workflow_seed.rb
