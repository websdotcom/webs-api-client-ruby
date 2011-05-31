Gem::Specification.new do |s|
	s.name = 'websapi'
	s.rubyforge_project = 'websapi'
	s.version = '0.1.1.2'
	s.platform = Gem::Platform::RUBY
	s.required_rubygems_version = Gem::Requirement.new('>= 1.2') if s.respond_to? :required_rubygems_version=
	s.authors = ['Patrick Carroll']
	s.email = 'patrick@webs.com'
	s.date = '2011-01-04'
	s.description = 'Client for the Webs.com REST API.'
	s.files = `git ls-files`.split("\n") + ['lib/websapi.rb']
	s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.homepage = 'http://github.com/websdotcom/webs-api-client-ruby'
	s.summary = 'Client for the Webs.com REST API.'
	s.require_paths = ['lib']

	s.add_dependency('json')

	s.add_development_dependency('mocha')

	if s.respond_to? :specification_version then
		current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
		s.specification_version = 3
	end
end
