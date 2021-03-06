#!/usr/bin/env ruby
# vim: set ts=2 sw=2 expandtab:
#
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
    stats = run('show stat')
    unless stats.respond_to?('each') then return nil end
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
      @stats.keys.sort
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

  # Return UP servers as array
  def up(service)
    find(service, 'UP')
  end

  # Return MAINT servers as array
  def maint(service)
    find(service, 'MAINT')
  end

  # Return DOWN servers as array
  def down(service)
    find(service, 'DOWN')
  end

  # Return a ratio of the backend servers that are UP (between 0 and 1)
  # E.g if ratio <= 0.5 then at least half of the backend servers are down
  def upratio(service)
    up(service).length.to_f / backends(service).length
  end

  private
  # Generic function for up,down,maint etc to use to match servers
  def find(service, state)
    out = Array.new
    backends(service).each do |this|
      if @stats[service][this]['status'] == state
        out = out << this
      end
    end
    out
  end
end
