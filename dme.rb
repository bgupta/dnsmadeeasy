#!/usr/bin/env ruby
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
# v0.3 May 24, 2011 - Replaced sheeling out to curl with native ruby rest-client call

# Make sure the dnsmeapi.properties file is available in the location from which you run this

require 'time'
require 'openssl'
require 'rest_client'
require 'json'

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

hmac = OpenSSL::HMAC.hexdigest('sha1', secretKey, requestDate)

response = RestClient.get 'http://api.dnsmadeeasy.com/V1.2/domains/brandorr.com/records', 
                          :"x-dnsme-apiKey" => apiKey, 
                          :"x-dnsme-hmac" => hmac, 
                          :"x-dnsme-requestDate" => requestDate, 
                          :accept =>:json
results = JSON.parse(response.to_str)
nameresults = results.select {|x| x["name"] == "www" and x["type"] == "A"}

#Prints the entire returned record set in "Pretty JSON"
puts JSON.pretty_generate(nameresults)

# Prints the recordids of the returned array of records
nameresults.each {|x| puts x["id"]}
