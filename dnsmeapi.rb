#!/opt/local/bin/ruby
# Copyright (C) 2011 Vijay Brian Gupta brian.gupta@brandorr.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# v0.2 May 22, 2011 - Replicated functionality of perl script http://www.dnsmadeeasy.com/enterprisedns/api.html
#
# Make sure the dnsmeapi.properties file is available in the location from which you run this

require 'time'
require 'uri'
require 'openssl'

dmepropertyfile = "dnsmeapi.properties"
requestDate = Time.now.httpdate

 def load_properties(propertyfile)
    properties = {}
    File.open(propertyfile, 'r') do |propertyfile|
      propertyfile.read.each_line do |line|
        line.strip!
        if (line[0] != ?# and line[0] != ?=)
          i = line.index('=')
          if (i)
            properties[line[0..i - 1].strip] = line[i + 1..-1].strip
          else
            properties[line] = ''
          end
        end
      end
    end
    properties
  end

prophash = load_properties dmepropertyfile
apiKey = prophash["apiKey"]
secretKey = prophash["secretKey"]

hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'), secretKey, requestDate)

apiKeyHeader = "x-dnsme-apiKey:" + apiKey;
hmacHeader = "x-dnsme-hmac:" + hmac;
requestDateHeader = "x-dnsme-requestDate:" + "\"" + requestDate + "\"";

puts `curl -s #{ARGV.join(" ")} --header #{apiKeyHeader} --header #{hmacHeader} --header #{requestDateHeader}`
