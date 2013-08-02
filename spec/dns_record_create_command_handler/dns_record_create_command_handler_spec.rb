require 'spec_helper'
require_relative "../../dns_record_create_command_handler/dns_record_create_command_handler"

describe Daemons::DnsRecordCreateCommandHandler do
  subject { Daemons::DnsRecordCreateCommandHandler.new() }

  let(:good_message_hash) {
    {
      "Message"=>{
        "request_id"=>1,
        "instance_id"=>"i-f4819cb9",
        "instance_name"=>"some_hostname",
        "domain"=>"some_domain"
      }
    }
  }
  let(:good_message_json) { good_message_hash.to_json }
  let(:good_payload_json) { good_message_json["Message"].to_json }

  describe "#handle_message" do
    it "Receives a correct SQS message and proceeds" do
      expect{subject.handle_message(good_message_json)}.not_to be false
    end
  end
  
end
