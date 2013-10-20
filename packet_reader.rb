#!/usr/bin/env ruby
require 'rubygems'
require 'pcaplet'
require 'http/parser'
require 'pp'
require 'zlib'
require 'json'

httpdump = Pcaplet.new('-s 1500 -i eth1')

HTTP_REQUEST = Pcap::Filter.new('tcp and dst port 80', httpdump.capture)
HTTP_RESPONSE = Pcap::Filter.new('tcp and src port 80', httpdump.capture)

def empty_communication
  { :sent => [], :receipt => [] }
end

def print_communication(com)
  request_parser = Http::Parser.new
  response_parser = Http::Parser.new
  response_body = ""

  request_parser.on_headers_complete = proc do
    pp request_parser.request_url
    pp request_parser.headers
  end

  response_parser.on_headers_complete = proc do
    pp response_parser.headers
  end

  response_parser.on_body = proc do |chunk|
    response_body << chunk
  end

  response_parser.on_message_complete = proc do
    if response_parser.headers["Content-Encoding"] == 'gzip'
      body = Zlib::GzipReader.wrap(StringIO.new(response_body)) do |gz|
        JSON.parse(gz.read)
      end

      pp body
    else
      p response_body
    end
  end

  com[:sent].each do |packet|
    request_parser << packet.tcp_data
  end
  com[:receipt].each do |packet|
    response_parser << packet.tcp_data
  end

end

active = false
current_communication = empty_communication

httpdump.add_filter(HTTP_REQUEST | HTTP_RESPONSE)
httpdump.each_packet {|pkt|
  case pkt
  when HTTP_REQUEST
    if pkt.tcp_syn?
      puts "-----------------------------------------------START-----------------"
      active = true
      current_communication = empty_communication
    end
    if active && pkt.tcp_data_len > 0
      current_communication[:sent] << pkt
      print ">"
    end
  when HTTP_RESPONSE
    if active && pkt.tcp_data_len > 0
      current_communication[:receipt] << pkt
      print "<"
    end
    if pkt.tcp_fin? && pkt.tcp_ack?
      print "\n"
      active = false
      print_communication(current_communication)
      print "\n"
    end
  end
}
