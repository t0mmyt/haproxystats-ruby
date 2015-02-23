#!/usr/bin/env ruby

require 'haproxystats'

socket = '/var/run/haproxy.stats'

# Create stats object and bind to socket
ha = HAProxyStats.new(socket)

# Tell stats object to slurp some stats
ha.retrieve

# Get a list of services
my_services = ha.services
puts "#{my_services.length} services found"

# How many backends are up per service
my_services.each do |service|
    puts "#{service}: #{ha.up(service).length} of #{ha.backends(service).length}"
end

# What ratio of servers are up per service
my_services.each do |service|
    puts "#{service}: #{ha.upratio(service)}"
end
