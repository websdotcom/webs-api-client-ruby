#!/usr/bin/env ruby

require 'test/unit'
require 'mocha'
require 'websapi'


class TestWebsAPIRequest < Test::Unit::TestCase
	def setup
		@request = WebsAPIRequest.new('apps/%s')
	end


	def test_make_url
		assert_equal @request.make_url(['foo']), 'https://api.webs.com/apps/foo'

		@request = WebsAPIRequest.new('sites/%s/apps/%s')
		assert_equal @request.make_url(['foo', 'bar']), 'https://api.webs.com/sites/foo/apps/bar'
	end

	def test_make_url__not_enough_args
		assert_raise WebsAPIException do
			@request.make_url([])
		end
	end

	def test_make_url__too_many_args
		assert_raise WebsAPIException do
			@request.make_url(['foo', 'bar'])
		end
	end
end


class TestWebsAPI < Test::Unit::TestCase
	def setup
		@api = WebsAPI.new
	end


	def test_respond_to?
		assert @api.respond_to?(:get_site_members)
		assert @api.respond_to?(:get_site)
		assert @api.respond_to?(:get_templates)
		assert !@api.respond_to?(:foo)
	end

	def test_method_missing
		@api.stubs(:http_request).returns('{"foo":1}')
		# XXX need to intercept the call to http_request
	end

	def test_method_missing__no_method
		assert_raise NoMethodError do
			@api.foo
		end
	end

	def test_method_missing__oauth_token
		@api = WebsAPI.new('token')
#		@api.uninstall_app('patrick', 'calendar') XXX 
	end

	def test_method_missing__no_oauth_token
		assert_raise WebsAPIException do
			@api.uninstall_app('patrick', 'calendar')
		end
	end

	def test_http_request
		# XXX mock out Net::HTTP
	end
end
