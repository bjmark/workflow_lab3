ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tranche', 'tranches'
  inflect.irregular 'status', 'statuses'
end

Dir[
  Rails.root + 'lib/**/**.rb',
  Rails.root + 'app/models/ext/**/**.rb',
  Rails.root + 'app/models/concerns/**.rb'
].each do |file|
  require file
end
