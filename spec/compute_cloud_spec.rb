require File.dirname(__FILE__) + '/spec_helper'
require "rubygems"
require "harp_runtime"
require "harp-runtime/cloud/cloud_mutator"

instance_resource = {
  "type" => "Std::ComputeInstance",
  "imageId" => "ami-d0f89fb9",
  "instanceType" => "t1.micro"
}

elastic_ip_resource = {
  "type" => "Std::ElasticIP"
}

eip_association_resource = {
  "type" => "Std::ElasticIPAssociation",
}

security_group_resource = {
  "type" => "Std::SecurityGroup",
  "name" => "web-security-group",
  "description" => "A web security group"
}

security_group_resource_2 = {
  "type" => "Std::SecurityGroup",
  "name" => "web-security-group-2",
  "description" => "A web security group 2"
}

volume_resource = {
  "type" => "Std::Volume",
  "availability_zone" => "us-east-1",
  "size" => 5
}

vpc_resource = {
  "type" => "Std::Vpc",
  "cidr_block" => "10.1.2.0/24"
}

internet_gateway_resource = {
  "type" => "Std::InternetGateway"
}

vpc_gateway_attachment_resource = {
  "type" => "Std::VpcGatewayAttachment",
  "internet_gateway_id" => "",
  "vpc_id" => ""
}

dhcp_option_resource = {
  "type" => "Std::DhcpOption",
  "dhcp_configuration_set" => {},
  "tag_set" => {}
}

dhcp_option_association_resource = {
  "type" => "Std::DhcpOptionAssociation",
  "dhcp_options_id" => "",
  "vpc_id" => ""
}

shared_context 'when have an instance' do
  let(:server_id) do
    inst = mutator.create("test_inst1", instance_resource)
    inst.instance_variable_get(:@id)
  end
end

shared_context 'when have an internet gateway' do
  let(:gateway_id) do
    inst = mutator.create("test_gateway1", internet_gateway_resource)
    inst.instance_variable_get(:@id)
  end
end

shared_context 'when have an eip' do
  let(:eip) do
    @new_eip = mutator.create("test_eip1", elastic_ip_resource)
    @new_eip.instance_variable_get(:@id)
  end
  let(:eip_association) do
    eip_association_resource["public_ip"] = eip
    eip_association_resource["server_id"] = server_id
    @eip_association = mutator.create("test_eip_asso", eip_association_resource)
    @eip_association.instance_variable_get(:@id)
  end
end

shared_context 'when have a vpc' do
  let(:vpc) do
    @new_vpc = mutator.create("test_vpc1", vpc_resource)
    @new_vpc.instance_variable_get(:@id)
  end
  let(:internet_gateway) do
    @new_gateway = mutator.create("test_gateway1", internet_gateway_resource)
    @new_gateway.instance_variable_get(:@id)
  end
  let(:dhcp_option) do
    @new_dhcp_option = mutator.create("test_dhcp_option1", dhcp_option_resource)
    @new_dhcp_option.instance_variable_get(:@id)
  end
  let(:vpc_gateway_attachment) do
    vpc_gateway_attachment_resource["internet_gateway_id"] = internet_gateway
    vpc_gateway_attachment_resource["vpc_id"] = vpc
    @new_gateway_attachment = mutator.create("test_gateway_attach", vpc_gateway_attachment_resource)
    @new_gateway_attachment.instance_variable_get(:@id)
  end
  let(:dhcp_option_association) do
    dhcp_option_association_resource["dhcp_options_id"] = dhcp_option
    dhcp_option_association_resource["vpc_id"] = vpc
    @new_dhcp_option_association = mutator.create("test_dhcp_option_association", dhcp_option_association_resource)
    @new_dhcp_option_association.instance_variable_get(:@id)
  end
end

describe Harp::Cloud::CloudMutator, "#create" do
  include_context "when have mutator"

  before do

  end

  it "creates a cloud instance" do
    result = mutator.create("test_inst1", instance_resource)
    verify_created(result, "test_inst1", ComputeInstance)
  end

  it "creates a security group" do
    result = mutator.create("test_sg1", security_group_resource)
    verify_created(result, "test_sg1", SecurityGroup)
    expect(result.description).to eq("A web security group")
  end

  describe Harp::Cloud::CloudMutator, "#create eip" do
    include_context "when have an eip"

    it "creates elastic ip" do
      eip
      verify_created(@new_eip, "test_eip1", ElasticIP)
    end

    describe Harp::Cloud::CloudMutator, "#create eip_association" do
      include_context "when have an instance"

      it "creates elastic ip association" do
        eip_association
        verify_created(@eip_association, "test_eip_asso", ElasticIPAssociation)
      end
    end
  end

  it "creates a volume" do
    result = mutator.create("test_vol1", volume_resource)
    verify_created(result, "test_vol1", Volume)
  end
  
  describe Harp::Cloud::CloudMutator, "#create vpc" do
    include_context "when have a vpc"

    it "creates a vpc" do
      vpc
      verify_created(@new_vpc, "test_vpc1", Vpc)
    end
    
    it "creates an internet gateway" do
      internet_gateway
      verify_created(@new_gateway, "test_gateway1", InternetGateway)
    end
    
    it "creates a dhcp option" do
      dhcp_option
      verify_created(@new_dhcp_option, "test_dhcp_option1", DhcpOption)
    end

    it "creates vpc gateway attachment" do
      vpc_gateway_attachment
      verify_created(@new_gateway_attachment, "test_gateway_attach", VpcGatewayAttachment)
    end
    
    it "creates dhcp option association" do
      dhcp_option_association
      verify_created(@new_dhcp_option_association, "test_dhcp_option_association", DhcpOptionAssociation)
    end
  end
end

describe Harp::Cloud::CloudMutator, "#destroy" do
  include_context "when have mutator"

  describe Harp::Cloud::CloudMutator, "#destroy eip" do
    include_context "when have mutator"
    include_context "when have an eip"
    include_context "when have an instance"

    it "destroys an elastic ip" do
      eip
      result = mutator.destroy("test_eip1", elastic_ip_resource)
      verify_destroyed(result, "test_eip1", ElasticIP)
    end

    describe Harp::Cloud::CloudMutator, "#destroy eip_association" do

      it "destroys an elastic ip association" do
        eip_association
        result = mutator.destroy("test_eip_asso", eip_association_resource)
        verify_destroyed(result, "test_eip_asso", ElasticIPAssociation)
      end
    end
  end

  describe Harp::Cloud::CloudMutator, "#destroy instance" do
    include_context "when have an instance"

    it "destroys a cloud instance" do
      server_id
      result = mutator.destroy("test_inst1", instance_resource)
      verify_destroyed(result, "test_inst1", ComputeInstance)
    end
  end

  it "destroys a security group" do
    created = mutator.create("test_sg2", security_group_resource_2)
    result = mutator.destroy("test_sg2", security_group_resource_2)
    verify_destroyed(result, "test_sg2", SecurityGroup)
  end
  it "destroys a volume" do
    created = mutator.create("test_vol1", volume_resource)
    result = mutator.destroy("test_vol1", volume_resource)
    verify_destroyed(result, "test_vol1", Volume)
  end
  
  describe Harp::Cloud::CloudMutator, "#destroy vpc" do
    include_context "when have a vpc"

    it "destroys a vpc" do
      vpc
      result = mutator.destroy("test_vpc1", vpc_resource)
      verify_destroyed(result, "test_vpc1", Vpc)
    end
    it "destroys an internet gateway" do
      internet_gateway
      result = mutator.destroy("test_gateway1", internet_gateway_resource)
      verify_destroyed(result, "test_gateway1", InternetGateway)
    end
    it "destroys a dhcp option" do
      dhcp_option
      result = mutator.destroy("test_dhcp_option1", dhcp_option_resource)
      verify_destroyed(result, "test_dhcp_option1", DhcpOption)
    end
    it "destroys a vpc gateway attachment" do
      vpc_gateway_attachment
      result = mutator.destroy("test_gateway_attach", vpc_gateway_attachment_resource)
      verify_destroyed(result, "test_gateway_attach", VpcGatewayAttachment)
    end
    it "destroys a dhpc option association" do
      dhcp_option_association
      result = mutator.destroy("test_dhcp_option_association", dhcp_option_association_resource)
      verify_destroyed(result, "test_dhcp_option_association", DhcpOptionAssociation)
    end
  end
end
