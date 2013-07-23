#!/usr/bin/env ruby
require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'ec2_booted'

subscriber = Daemons::Subscriber.new

case ARGV[0]
when "run"
  begin
    subscriber.subscribe(
      Daemons::Config.instance['sqs']['booted_ec2_queue'],
      Daemons::EC2Booted.new)
  rescue => e
    puts "#{e}"
    retry
  end
end
