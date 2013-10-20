# -*- coding: utf-8 -*-
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'resolv'
require 'webrick'
require 'webrick/httpproxy'
require 'zlib'
require 'json'
require "cgi"

require 'filters/base_filter'
require 'filters/egg_filter'
require 'filters/save_data_filter'
require 'filters/weak_monster_filter'

google_dns = Resolv::DNS.new(nameserver: ['8.8.8.8'])
API_IP = google_dns.getaddress('api-pad.gungho.jp').to_s


class PadApiProxyServer < WEBrick::HTTPProxyServer
  def initialize(config={}, default=WEBrick::Config::HTTP)
    super(config, default)
    @filters = []
  end

  def add_filter(filter)
    @filters << filter
  end

  def service(req, res)
    raise WEBrick::HTTPStatus::BadRequest if block_request(req)

    if req.request_method == "CONNECT"
      do_CONNECT(req, res)
    else
      proxy_service(req, res)
    end

    callback(req, res)
  end

  def perform_proxy_request(req, res)
    uri = req.request_uri
    path = uri.path.dup
    path << "?" << uri.query if uri.query
    header = setup_proxy_header(req, res)
    upstream = setup_upstream_proxy_authentication(req, res, header)
    response = nil

    http = Net::HTTP.new(API_IP, uri.port, upstream.host, upstream.port)
    http.start do
      if @config[:ProxyTimeout]
        ##################################   these issues are
        http.open_timeout = 30   # secs  #   necessary (maybe bacause
        http.read_timeout = 60   # secs  #   Ruby's bug, but why?)
        ##################################
      end
      response = yield(http, path, header)
    end

    # Persistent connection requirements are mysterious for me.
    # So I will close the connection in every response.
    res['proxy-connection'] = "close"
    res['connection'] = "close"

    # Convert Net::HTTP::HTTPResponse to WEBrick::HTTPResponse
    res.status = response.code.to_i
    choose_header(response, res)
    set_cookie(response, res)
    set_via(res)
    res.body = response.body
  end

  private
  def block_request(req)
    @filters.any? do |f|
      if f.filter_on == :any || f.filter_on.include?(req.query['action'])
        puts "Checking #{f.class.name}..."
        f.filter(req)
      end
    end
  end

  def callback(req, res)
    @filters.each do |f|
      if f.callback_on == :any || f.callback_on.include?(req.query['action'])
        puts "Calling back #{f.class.name}..."
        f.callback(req, res)
      end
    end
  end
end

# this server needs root permission
server = PadApiProxyServer.new(BindAddress: '0.0.0.0', Port: 80)
server.add_filter(SaveDataFilter.new)
# server.add_filter(EggFilter.new([321], 1))
# server.add_filter(WeakMonsterFilter.new)
# 178 キングメタルドラゴン
# 181 キングゴールドドラゴン
# TODO: filter to replace all mobs

# apparently set signal handler to stop
shutdown_proc = ->( sig ){ server.shutdown() }
[ :INT, :TERM ].each{ |e| Signal.trap( e, &shutdown_proc ) }

server.start
