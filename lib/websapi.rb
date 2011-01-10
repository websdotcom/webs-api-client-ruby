#!/usr/bin/env ruby
# 
# API client for the Webs.com REST API.  
#
# http://wiki.developers.webs.com/wiki/REST_API
#
# @author Patrick Carroll <patrick@webs.com>
#
# TODO
# * handle posting data (for example when installing an app or updating a site)
#
require 'json'
require 'net/https'
require 'uri'


class WebsAPIException < StandardError; end


class WebsAPIRequest
	API_URL = 'https://api.webs.com/'

	attr_accessor :url, :method, :requires_oauth_token

	alias requires_oauth_token? requires_oauth_token


	def initialize(url, method=:GET, requires_oauth_token=false)
		@url = url.start_with?(API_URL) ? url : API_URL + url
		@method = method
		@requires_oauth_token = requires_oauth_token
	end

	def make_url(args)
		required_args = @url.count('%')
		if args.size != required_args
			raise WebsAPIException, 
				"URL #@url requires #{required_args} arguments"
		end

		sprintf(@url, *args)
	end

	def to_s
		"#@method #@url"
	end
end


class WebsAPI
	# the mapping of WebsAPIRequest objects to API calls
	API_URLS = {
		:get_apps => WebsAPIRequest.new('apps/'),
		:get_app => WebsAPIRequest.new('apps/%s/'),

		:get_templates => WebsAPIRequest.new('templates/'),
		:get_template => WebsAPIRequest.new('templates/%s/'),
		:get_template_styles => WebsAPIRequest.new('templates/%s/styles/'),
		:get_template_style => WebsAPIRequest.new('templates/%s/styles/%s/'),

		:get_site => WebsAPIRequest.new('sites/%s/'),
		# :update_site => WebsAPIRequest.new('sites/%s/', :PUT),
		:get_site_feeds => WebsAPIRequest.new('sites/%s/feeds/'),
		:get_site_navbar_links => WebsAPIRequest.new('sites/%s/navbar/'),
		:get_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/%s/'),
		:add_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/', :POST, true),
		:remove_site_navbar_link => WebsAPIRequest.new('sites/%s/navbar/%s/', :DELETE, true),
		:get_site_sidebars => WebsAPIRequest.new('sites/%s/sidebars/'),
		:get_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/'),
		:add_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/', :POST, true),
		:remove_site_sidebar => WebsAPIRequest.new('sites/%s/sidebars/%s/', :DELETE, true),

		:get_installed_apps => WebsAPIRequest.new('sites/%s/apps/'),
		:get_installed_app => WebsAPIRequest.new('sites/%s/apps/%s/'),
		:install_app => WebsAPIRequest.new('sites/%s/apps/%s/', :POST, true),
		:uninstall_app => WebsAPIRequest.new('sites/%s/apps/%s/', :DELETE, true),

		:get_site_files => WebsAPIRequest.new('sites/%s/files/'),
		:get_site_file => WebsAPIRequest.new('sites/%s/files/%s/'),
		# :add_file_to_site => WebsAPIRequest.new('sites/%s/
		# :update_file_on_site =>
		
		:get_site_members => WebsAPIRequest.new('sites/%s/members/'),
		:get_site_member => WebsAPIRequest.new('sites/%s/members/%s/'),
		:update_site_member => WebsAPIRequest.new('sites/%s/members/%s/', :PUT, true),
		:join_site_member => WebsAPIRequest.new('sites/%s/members/', :POST, true),
		:unsubscribe_site_member => WebsAPIRequest.new('sites/%s/members/%s/', :DELETE, true),
		:get_site_member_friends => WebsAPIRequest.new('sites/%s/members/%s/friends/'),
		:get_site_member_feeds => WebsAPIRequest.new('sites/%s/members/%s/feeds/'),
	}

	attr_accessor :oauth_token


	def initialize(oauth_token=nil)
		@oauth_token = oauth_token
	end


	def respond_to?(sym)
		super or API_URLS.has_key? sym
	end

	def method_missing(sym, *args, &block)
		unless API_URLS.has_key? sym
			raise NoMethodError, 
				"undefined method '#{sym}' for #{inspect}:#{self.class}"
		end

		# get the WebsAPIRequest mapping 
		api_url = API_URLS[sym]
		if api_url.requires_oauth_token? and not @oauth_token
			raise WebsAPIException, 
				"#{api_url} requires that an OAuth token is set"
		end

		# pagination arguments
		page_num, page_size = nil, nil
		if args.last.is_a? Hash
			hash_args = args.pop
			page_num, page_size = hash_args[:page_num], hash_args[:page_size]
		end


		url = api_url.make_url(args) 

		query = []
		query << "oauth_token=#{@oauth_token}" if @oauth_token
		query << "page=#{page_num}" if page_num
		query << "pagesize=#{page_size}" if page_size

		url << "?" + query.join("&") if not query.empty?

		JSON.parse http_request(url, api_url.method)
	end


	private

	def http_request(url, method)
		uri = URI.parse url
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		request = case method
				  when :GET 
					  Net::HTTP::Get.new uri.request_uri
				  when :PUT
					  Net::HTTP::Put.new uri.request_uri
				  when :POST
					  Net::HTTP::Post.new uri.request_uri
				  when :DELETE
					  Net::HTTP::Delete.new uri.request_uri
				  else
					  raise WebsAPIException, 
						  "Unknown request method: #{method.to_s} for #{url}"
				  end

		request['Accept'] = 'application/json'
		http.request(request).body
	end
end

