#!/usr/bin/env ruby
# vim: set ts=2 sw=2 expandtab:
#
require 'socket'
require 'csv'

# Container class for the socket
# Intended to be inherited by othere classes that require use fo the stats
# socket (e.g. HAProxyStats)
class HAProxySocket
  # Check we have a socket at location and that we can open it
  def initialize(location)
    @location = location
    raise ArgumentError, "#{location} does not appear to be a socket." unless File.socket?(location)
    raise IOError, 'Cannot read/write to socket at ${location}' unless show_info
  end

  # Open a socket, run a command, collect output and close
  def run(command)
    sock = UNIXSocket.new @location
    sock.puts command
    out = ''
    first_char = sock.read 2
    if first_char == '# '
      out = CSV.parse(sock.read)
      sock.close
      return out
    end
    out = first_char + sock.read
    sock.close
    out
  end

  # Show info from haproxy
  def show_info
      run('show info')
  end
end
