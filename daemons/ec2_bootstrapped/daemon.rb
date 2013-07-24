#!/usr/bin/env ruby
require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'ec2_bootstrapped'

config = Daemons.config
sqs_poller = Daemons::Subscriber.new()

case ARGV[0]
when "run"
  #begin
    sqs_poller.subscribe(
      "bootstrap_ec2_instance",
      Daemons::EC2Bootstrapped.new(config)
    )
  #rescue => e
  #	sleep(1)
  #  puts "#{e}"
  #  retry
  #end
end
