#!/usr/bin/env ruby
# vim: set ts=2 sw=2 expandtab:
#
require 'socket'
require 'csv'
require 'pp'

# Container class for the socket ... probably shouldn't be called directly
class HAProxySocket
  def initialize(location)
    @location = location
  end

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
    # 
    run('show stat').each do |line|
      if not defined? @headers
        # First row of CSV output is our headers
        @headers = line
      else
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
    my_backends.each do |this|
      if @stats[service][this]['status'] == 'UP'
        up += 1
      end
    end
    up.to_f / my_backends.length.to_f
  end
end


ha = HAProxyStats.new '/var/run/haproxy.stats'
ha.retrieve

ha.services.each do |service|
  puts service + " " + ha.upratio(service).to_s
end
