#!/usr/bin/env ruby
# A more advanced example of the haproxystats gem that will send an email when
# the state of a backend changes.
# 
# Intended to be run every minute in cron (dirty but temporary)
#
# Tom Taylor <tom@tommyt.co.uk>
#
#: vim: set ts=2 sw=2 et:
require 'rubygems'
require 'socket'
gem 'haproxystats', '>=0.0.6'
require 'haproxystats'

socket_location = '/var/run/haproxy.stats'

ha = HAProxyStats.new(socket_location)

ha.retrieve

puts ha.services
