require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:spec) do |t|
  t.libs << "spec"
  t.libs << "lib"
  t.test_files = FileList["spec/**/*_spec.rb"]
end

Rake::TestTask.new(:spec_ipaddr) do |t|
  t.libs << "lib"
  t.test_files = FileList["spec/extra/**/test_ipaddr.rb"]
end

task default: %i[spec spec_ipaddr]
