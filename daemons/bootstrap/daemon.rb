#!/usr/bin/env ruby
require_relative '../common/subscriber'

case ARGV[0]
when "run"
  Subscriber.new('queue_name', Daemons::Bootstrap.new)
end

