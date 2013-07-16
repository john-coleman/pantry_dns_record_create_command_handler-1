require_relative 'ec2_runner'

describe EC2Runner do
  let(:fog) { Fog::Computer.new(provider: 'AWS')}
  let(:test_hash){ 
    {
      pantry_request_id: "-1",
      instance_name: "sqs test",
      flavor: "t1.micro",
      ami: "ami-fedfd48a",
      team: "test team"
    }
  }
  let(:good_msg) { test_hash.to_json }
  let(:bad_msg) { "lajdflajdsflslfdj" }
  before :each do 
    @ec2_runner = EC2Runner.new(true)
  end

  describe "#machine_already_booted" do
    it "Takes a non existing machine ID and returns false" do 
      expect(@ec2_runner.machine_already_booted(-1)).to be false
    end
  end

  describe "#boot_machine" do 
    it "Takes machine details and boots an ec2 instance" do 
      expect( @ec2_runner.boot_machine(
        1,
        "test_name",
        "t1.micro",
        "ami-fedfd48a",
        "test_team" )
      ).not_to be nil
    end
  end

  describe "#handle_message" do 
    it "Receives an incorrect SQS message and errors" do 
      @ec2_runner.handle_message(bad_msg).should == false
    end

    it "Receives a correct SQS message and boots a machine" do
      @ec2_runner.handle_message(good_msg).should == true
    end
  end

end