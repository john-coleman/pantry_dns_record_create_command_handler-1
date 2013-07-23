#!/usr/bin/env ruby
require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'ec2_booted'

config = Daemons.config
config.configure_aws
sqs_poller = Daemons::Subscriber.new()
case ARGV[0]
when "run"
  begin
    sqs_poller.subscribe(config['sqs']['booted_ec2_queue'],Daemons::EC2Booted.new(config))
  rescue => e
    puts "#{e}"
    retry
  end
end
