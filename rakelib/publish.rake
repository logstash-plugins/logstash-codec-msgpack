require "gem_publisher"

desc "Publish gem to RubyGems.org"
task :publish_gem do |t|
  files = Dir.glob(File.expand_path('../*.gemspec',File.dirname(__FILE__)))
  files.each do |gemfile|
    if gemfile.split('-')[-1] == 'java.gemspec'
      tag_prefix = 'v-java'
    else
      tag_prefix = 'v'
    end
    gem = GemPublisher.publish_if_updated(gemfile, :rubygems, {:tag_prefix => tag_prefix})
    puts "Published #{gem}" if gem
  end
end

