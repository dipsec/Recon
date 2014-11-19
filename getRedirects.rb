#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'optparse'

class BetterResponse
	attr_accessor :response, :request, :uri

	def initialize(response, request, uri)
		@response = response
		@request = request
		@uri = uri
	end
end

def fetch_response(uri, limit = 10)
	if limit == 0	
		raise StandardError, "Too many HTTP redirects"
	end

	o_URI = URI.parse(uri)

	o_HTTP = Net::HTTP.new(o_URI.host, o_URI.port)

	if o_URI.scheme == "https"
		o_HTTP.use_ssl = true
		o_HTTP.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end

	response = o_HTTP.request_get(o_URI.request_uri)

	case response
		when Net::HTTPInformation, Net::HTTPSuccess, Net::HTTPClientError, 
			Net::HTTPServerError, Net::HTTPUnknownResponse then 
			BetterResponse.new(response, o_HTTP, o_URI)
		when Net::HTTPRedirection then 
			fetch_response(response['location'], limit - 1)
		else
			BetterResponse.new(response, o_HTTP, o_URI)
	end
end

options = {}

optparse = OptionParser.new { |opts|
	opts.banner = "Usage: getRedirects.rb [options]"
	options[:input] = false
	opts.on( '-i', '--input FILE', "Input file, one URL per line") { |file|
		options[:input] = file
	}
	opts.on( '-o', '--output FILE', "Output CSV file") { |file|
		options[:output] = file
	}
	opts.on( '-h', '--help', "Display this screen" ) {
		puts opts
	}
}

optparse.parse!

if not options[:input] or not options[:output]
	puts optparse
	exit
end

if not File.exists?(options[:input])
	puts "ERROR: Input file not found."
	puts optparse
	exit
end

if File.exists?(options[:output])
	puts "ERROR: Output file already exists."
	puts optparse
	exit
end

o_OutFile = File.new(options[:output], "w")
o_InFile = File.open(options[:input], "r")

o_OutFile.puts("SOURCE,RESULT")
o_InFile.each_line { |line|
	begin
		response = fetch_response(line.chomp)
		if line.chomp == response.uri.to_s then
			o_OutFile.printf("%s,\n", line.chomp)
		else
			o_OutFile.printf("%s,%s\n", line.chomp, response.uri)
		end
	rescue SocketError
		o_OutFile.printf("%s,ERROR: Could not resolve\n", line.chomp)
	rescue
		o_OutFile.printf("%s,ERROR: Unknown\n", line.chomp)
	end
}
