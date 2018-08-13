lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'
require_relative 'lib/sensu-plugins-kubernetes'

Gem::Specification.new do |s|
  s.authors                = ['Sensu-Plugins and contributors']
  s.date                   = Date.today.to_s
  s.description            = 'Provides monitoring for Kubernetes via Sensu (SendGrid Fork)'
  s.email                  = '<sensu-users@googlegroups.com>'
  s.executables            = Dir.glob('bin/**/*.rb').map { |file| File.basename(file) }
  s.files                  = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md Gemfile sendgrid-sensu-plugins-kubernetes.gemspec)
  s.homepage               = 'https://github.com/sensu-plugins/sensu-plugins-kubernetes'
  s.license                = 'MIT'
  s.metadata               = { 'maintainer'         => 'sensu-plugin',
                               'development_status' => 'active',
                               'production_status'  => 'unstable - testing recommended',
                               'release_draft'      => 'false',
                               'release_prerelease' => 'false' }
  s.name                   = 'sendgrid-sensu-plugins-kubernetes'
  s.platform               = Gem::Platform::RUBY
  s.post_install_message   = 'You can use the embedded Ruby by setting EMBEDDED_RUBY=true in /etc/default/sensu'
  s.require_paths          = ['lib']
  s.required_ruby_version  = '>= 2.1.0'
  s.summary                = 'Sensu plugins for kubernetes (SendGrid fork)'
  s.test_files             = s.files.grep(%r{^(test|spec|features)/})
  s.version                = SensuPluginsKubernetes::Version::VER_STRING

  s.add_runtime_dependency 'sensu-plugin',   '~> 1.2'
  s.add_runtime_dependency 'kubeclient',     '~> 2.3'
  s.add_runtime_dependency 'activesupport',  '< 5.0.0'

  s.add_development_dependency 'bundler',                   '~> 1.7'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4'
  s.add_development_dependency 'github-markup',             '~> 1.3'
  s.add_development_dependency 'pry',                       '~> 0.10'
  s.add_development_dependency 'rake',                      '~> 10.5'
  s.add_development_dependency 'redcarpet',                 '~> 3.2'
  s.add_development_dependency 'rubocop',                   '~> 0.40.0'
  s.add_development_dependency 'rspec',                     '~> 3.4'
  s.add_development_dependency 'yard',                      '~> 0.8'
end
