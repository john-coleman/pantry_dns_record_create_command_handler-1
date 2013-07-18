require 'spec_helper'
require "#{Rails.root}/daemons/ec2_runner/ec2_runner"
describe Daemons::EC2Runner do
  subject { Daemons::EC2Runner.new(true) }
  let(:fog) { Fog::Compute.new(provider: 'AWS')}
  let(:test_hash){ 
    {
      pantry_request_id: "",
      instance_name: "sqs test",
      flavor: "t1.micro",
      ami: "ami-fedfd48a",
      team_id: "test team",
      subnet_id: "subnet-f3c63a98", 
      security_group_ids: "sg-f94dc88e",
      ssh_key: '123456F'
    }
  }
  let(:good_msg) { test_hash.to_json }

  describe "#machine_already_booted" do
    it "Takes a non existing machine ID and returns false" do 
      expect(subject.machine_already_booted(-1)).to be false
    end
  end

  describe "#boot_machine" do 
    it "Takes machine details and boots an ec2 instance" do 
      expect{subject.boot_machine(
        1,
        "test_name",
        "t1.micro",
        "ami-fedfd48a",
        "test_team",
        "subnet-f3c63a98",
        "sg-f94dc88e" ); sleep(10)
      }.not_to be false
    end
  end

  describe "#handle_message" do 
    it "Receives a correct SQS message and boots a machine" do
      expect{
        subject.handle_message(good_msg)
      }.not_to be false    
    end
  end

end
