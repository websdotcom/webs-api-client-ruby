#!/usr/bin/env ruby1.9.1
# 
# API client for the Webs.com REST API.  
#
# http://wiki.developers.webs.com/wiki/REST_API
#
# @author Patrick Carroll <patrick@webs.com>
#
# TODO
# * need to support pagination
# * tests
# * handle posting data (for example when installing an app)
# * can the hash of request mappings be better expressed as a DSL?
#
require 'json'
require 'net/https'
require 'uri'


class WebsAPIRequest
	API_URL = 'https://api.webs.com/'

	attr_accessor :url, :arguments, :method, :requires_oauth_token


	def initialize(url, arguments=0, method=:GET, requires_oauth_token=false)
		@url = url.start_with?(API_URL) ? url : API_URL + url
		@arguments = arguments
		@method = method
		@requires_oauth_token = requires_oauth_token
	end

	def requires_oauth_token?
		@requires_oauth_token
	end

	def make_url(args)
		if arguments == 0
			@url
		elsif arguments == args.size
			sprintf(@url, *args)
		else
			raise Exception, "URL #@url requires #@arguments arguments"
		end
	end

	def to_s
		"#@method #@url"
	end
end


class WebsAPI
	# the mapping of WebsAPIRequest objects to API calls
	API_URLS = {
		:get_apps => WebsAPIRequest.new('apps/'),
		:get_app => WebsAPIRequest.new('apps/%s/', 1),

		:get_templates => WebsAPIRequest.new('templates/'),
		:get_template => WebsAPIRequest.new('templates/%s/', 1),
		:get_template_styles => WebsAPIRequest.new('templates/%s/styles/', 1),
		:get_template_style => WebsAPIRequest.new('templates/%s/styles/%s/', 2),

		:get_site => WebsAPIRequest.new('sites/%s/', 1),
		# :update_site => WebsAPIRequest.new('sites/%s/', 1, :PUT),
		:get_site_feeds => WebsAPIRequest.new('sites/%s/feeds/', 1),
		:get_site_navbar_links => WebsAPIRequest.new('sites/%s/navbar/', 1),
		:get_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/%s/', 2),
		:add_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/', 1, :POST, true),
		:remove_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/%s', 2, :DELETE, true),
		:get_site_sidebars => WebsAPIRequest.new('sites/%s/sidebars/', 1),
		:get_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/', 2),
		:add_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/', 2, :POST, true),
		:remove_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/', 2, :DELETE, true),

		:get_installed_app => WebsAPIRequest.new('sites/%s/apps/%s/', 2),
		:install_app => WebsAPIRequest.new('sites/%s/apps/%s/', 2, :POST, true),
		:uninstall_app => WebsAPIRequest.new('sites/%s/apps/%s/', 2, :DELETE, true),

		:get_site_files => WebsAPIRequest.new('sites/%s/files/', 1),
		:get_site_file => WebsAPIRequest.new('sites/%s/files/%s/', 2),
		# :add_file_to_site => WebsAPIRequest.new('sites/%s/
		# :update_file_on_site => 
		
		:get_site_members => WebsAPIRequest.new('sites/%s/members/', 1),
		:get_site_member => WebsAPIRequest.new('sites/%s/members/%s/', 2),
		:update_site_member => WebsAPIRequest.new('sites/%s/members/%s/', 2, :PUT, true),
		:join_site_member => WebsAPIRequest.new('sites/%s/members/', 1, :POST, true),
		:unsubscribe_site_member => WebsAPIRequest.new('sites/%s/members/%s/', 2, :DELETE, true),
		:get_site_member_friends => WebsAPIRequest.new('sites/%s/members/%s/friends/', 2),
		:get_site_member_feeds => WebsAPIRequest.new('sites/%s/members/%s/feeds/', 2),
	}

	attr_accessor :oauth_token


	def initialize(oauth_token=nil)
		@oauth_token = oauth_token
	end


	def respond_to?(sym)
		super or API_URLS.has_key?(sym)
	end

	def method_missing(sym, *args, &block)
		unless API_URLS.has_key?(sym)
			raise NoMethodError, 
				"undefined method '#{sym}' for #{inspect}:#{self.class}"
		end

		api_url = API_URLS[sym]
		if api_url.requires_oauth_token? and not @oauth_token
			raise Exception, 
				"#{api_url} requires that an OAuth token is set"
		end

		url = api_url.make_url(args)
		url << "?oauth_token=#{@oauth_token}" if @oauth_token

		JSON.parse(http_request(url, api_url.method))
	end


	protected

	def http_request(url, method)
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		request = case method
				  when :GET 
					  Net::HTTP::Get.new(uri.request_uri)
				  when :PUT
					  Net::HTTP::Put.new(uri.request_uri)
				  when :POST
					  Net::HTTP::Post.new(uri.request_uri)
				  when :DELETE
					  Net::HTTP::Delete.new(uri.request_uri)
				  end

		request['Accept'] = 'application/json'
		http.request(request).body
	end
end

