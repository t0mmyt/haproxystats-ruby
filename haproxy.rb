#!/usr/bin/env ruby
require 'socket'
require 'csv'
require 'pp'

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
end

class HAProxyStats < HAProxySocket
    attr_reader :stats

    def initialize(location)
        super location
        @stats = Hash.new
    end

    def retrieve(all=false)
        run('show stat').each do |line|
            if not defined? @headers
                @headers = line
            else
                this = Hash[*@headers.zip(line).flatten]
                if all or (this['pxname'] and not this['pxname'][0,1] == '_')
                    if this['pxname']
                        # Create hash if one doesn't exist
                        if not @stats[this['pxname']]
                            @stats[this['pxname']] = Hash.new
                        end
                        @stats[this['pxname']][this['svname']] = this
                    end
                end
            end
        end
    end

    def services
        @stats.keys
    end
    
    def backends(service)
        out = Array.new
        @stats[service].each do |k, v|
            if not (k == 'FRONTEND' or k == 'BACKEND')
                out = out << k
            end
        end
        out
    end

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
puts ha.upratio('click2call_ukld5p2000')
