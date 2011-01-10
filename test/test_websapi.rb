#!/usr/bin/env ruby

require 'test/unit'
require 'websapi'


class TestWebsAPIRequest < Test::Unit::TestCase
	def test_make_url
		request = WebsAPIRequest.new('apps/%s')
		assert_equal request.make_url(['foo']), 'https://api.webs.com/apps/foo'

		request = WebsAPIRequest.new('sites/%s/apps/%s')
		assert_equal request.make_url(['foo', 'bar']), 'https://api.webs.com/sites/foo/apps/bar'
	end

	def test_make_url__wrong_num_args
		request = WebsAPIRequest.new('apps/%s')
		assert_raise WebsAPIException do
			request.make_url([])
		end
	end
end


class TestWebsAPI < Test::Unit::TestCase

end
