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
        out = sock.read
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
        @out = Array.new
        run('show stat').each do |line|
            if not @headers
                @headers = line
            else
                @this = Hash[*@headers.zip(line).flatten]
                if all or (@this['pxname'] and not @this['pxname'][0,1] == '_')
                    if @this['pxname']
                        if not @stats[@this['pxname']] then @stats[@this['pxname']] = Array.new end
                        @stats[@this['pxname']] = @stats[@this['pxname']] << @this
                    end
                end
            end
        end
    end

    def services
        @stats.keys
    end
end

ha = HAProxyStats.new '/var/run/haproxy.stats'
ha.retrieve(all=true)

puts ha.services
