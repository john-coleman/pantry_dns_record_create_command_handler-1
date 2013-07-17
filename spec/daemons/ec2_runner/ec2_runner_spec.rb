require 'spec_helper'
require "#{Rails.root}/daemons/ec2_runner/ec2_runner"
describe Daemons::EC2Runner do
  subject { Daemons::EC2Runner.new(true) }

  let(:fog) { Fog::Computer.new(provider: 'AWS')}
  let(:test_hash){ 
    {
      pantry_request_id: "-1",
      instance_name: "sqs test",
      flavor: "t1.micro",
      ami: "ami-fedfd48a",
      team: "test team",
      subnet_id: "subnet-f3c63a98", 
      security_group_ids: "sg-f94dc88e"
    }
  }
  let(:good_msg) { test_hash.to_json }
  let(:bad_msg) { "lajdflajdsflslfdj" }

  describe "#machine_already_booted" do
    it "Takes a non existing machine ID and returns false" do 
      expect(subject.machine_already_booted(-1)).to be false
    end
  end

  describe "#boot_machine" do 
    it "Takes machine details and boots an ec2 instance" do 
      expect( subject.boot_machine(
        1,
        "test_name",
        "t1.micro",
        "ami-fedfd48a",
        "test_team",
        "subnet-f3c63a98",
        "sg-f94dc88e" )
      ).not_to be nil
    end
  end

  describe "#handle_message" do 
    it "Receives an incorrect SQS message and errors" do 
      subject.handle_message(bad_msg).should == false
    end

    it "Receives a correct SQS message and boots a machine" do
      subject.handle_message(good_msg).should == true
    end
  end

end
