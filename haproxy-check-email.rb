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
require 'haproxystats'
require 'socket'
require 'net/smtp'
require 'digest'

raise ArgumentError, '4 arguments needed! (socket, smtp_relay, mail_from, rcpt_to)' unless ARGV.length == 4
raise ArgumentError, 'First Argument should be a Unix socket' unless File.socket?(ARGV[0])

socket_location, smtp_host, mail_from, rcpt_to = ARGV.take(4)

# Stores md5 of last sent email to detect for state changes
hash_file = '/tmp/haproxy-check.md5'

hostname = Socket.gethostname

# Open socket and pull stats
ha = HAProxyStats.new(ARGV[0])
ha.retrieve

# Get array of services
my_services = ha.services

# Empty has for statuses of each service
status = Hash.new

# Iterate the services and get their status
my_services.each do |service|
  if ha.backends(service).length > 0
    r = ha.upratio(service)
    if r == 1.0
      status[service] = 'OK'
    elsif r < 1.0 and r >= 0.5
      # Less than 100% of backends are up
      status[service] = 'Degraded'
    elsif r < 0.5 and r > 0.0
      # 50% or less
      status[service] = 'Severe'
    elsif r == 0.0
      # All backends down
      status[service] = 'Critical'
    end
  end
end

# Create an email describing the state
body = ""
subject = ""
['OK', 'Degraded', 'Severe', 'Critical'].each do |this_status|
  my_services.each do |service|
    if defined? status[service] and status[service] == this_status
      subject = "Services #{this_status} on #{hostname}"
      body = body + "#{service} has #{ha.up(service).length} of #{ha.backends(service).length} backends up
        UP   : #{ha.up(service).inspect}
        DOWN : #{ha.down(service).inspect}
        MAINT: #{ha.maint(service).inspect}\n\n"
    end
  end
end

if body.length > 0 and defined? subject
  # Put email in to format for emailing
  message = <<-EOM
From:#{mail_from}To:#{rcpt_to}
Subject:#{subject}
#{body}
  EOM
  # Get md5 of email content
  message_md5 = Digest::MD5.hexdigest message
  old_md5 = nil

  # If we have an existing hash for an already sent email, get it
  if File.file?(hash_file)
    File.open(hash_file, 'r') do |f|
      old_md5 = f.read
    end
  end

  # Compare hash for old email and new and send email if differen
  if old_md5 != message_md5
    Net::SMTP.start(smtp_host) do |smtp|
      smtp.send_message message, mail_from, rcpt_to
    end
  end
  # Write our new md5 to file
  File.open(hash_file, 'w') do |f|
    f.write message_md5
  end
end
