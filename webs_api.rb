#!/usr/bin/env ruby1.9.1
require 'json'
require 'net/https'
require 'uri'


# 
# API client for the Webs.com REST API.  
#
# http://wiki.developers.webs.com/wiki/REST_API
#
# @author Patrick Carroll <patrick@webs.com>
#
class WebsApi
	API_URL = 'https://api.webs.com/'
	API_URIS = {
		:get_apps => 'apps/',
	}

	attr_accessor :oauth_token


	def initialize(oauth_token=nil)
		@oauth_token = oauth_token
	end

	def to_s
		# XXX
	end


	def responds_to?(sym)
		API_URIS.has_key?(sym)
	end

	def method_missing(sym, *args, &block)
		if not API_URIS.has_key?(sym)
			raise NoMethodError.new("undefined method '#{sym}' for #{inspect}:#{self.class}")
		end

		url = API_URL + API_URIS[sym]
		if @oauth_token then url << "?oauth_token=#{@oauth_token}" end

		JSON.parse(http_request(url))
	end


	def http_request(url)
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		request = Net::HTTP::Get.new(uri.request_uri)
		request['Accept'] = 'application/json'

		http.request(request).body
	end
end
