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

# Class for getting statistics
class HAProxyStats < HAProxySocket
  attr_reader :stats

  def initialize(location)
    # Get a socket (via super)
    super location
    @stats = Hash.new
  end

  # Function to extract the data from the stats socket
  # and put into @stats[service][server/aggregate]
  def retrieve(all = false)
    # run 'show stat' on the socket and iterate output
    run('show stat').each do |line|
      if not defined? @headers
        # First row of CSV output is our headers
        @headers = line
      else
        # @stats Hash populating magic
        this = Hash[*@headers.zip(line).flatten]
        if all or (this['pxname'] and not this['pxname'][0,1] == '_')
          if this['pxname']
            # Create hash if one doesn't exist
            unless @stats[this['pxname']]
              @stats[this['pxname']] = Hash.new
            end
            @stats[this['pxname']][this['svname']] = this
          end
        end
      end
    end
  end

  # Return an array of services
  def services
      @stats.keys
  end
    
  # Return an array of the backend servers for +service+
  def backends(service)
    out = Array.new
    # iterate the servers removing aggregates for FRONT/BACKEND
    @stats[service].each do |k, v|
      if not (k == 'FRONTEND' or k == 'BACKEND')
        out = out << k
      end
    end
    out
  end

  # Return a ratio of the backend servers that are UP (between 0 and 1)
  # E.g if ratio <= 0.5 then at least half of the backend servers are down
  def upratio(service)
    my_backends = backends(service)
    up = 0
    # iterate servers and count the UPs
    my_backends.each do |this|
      if @stats[service][this]['status'] == 'UP'
        up += 1
      end
    end
    # Return the ratio
    up.to_f / my_backends.length.to_f
  end
end
