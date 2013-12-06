require 'set'
require 'fog/core/model'
require 'harp-runtime/models/autoscale'
require 'json'

module Harp
  module Resources

    class LaunchConfiguration < AvailableResource

      include Harp::Resources

        attribute :id,                    :aliases => 'LaunchConfigurationName'
        attribute :arn,                   :aliases => 'LaunchConfigurationARN'
        attribute :associate_public_ip,   :aliases => 'AssociatePublicIpAddress'
        attribute :block_device_mappings, :aliases => 'BlockDeviceMappings'
        attribute :created_at,            :aliases => 'CreatedTime'
        attribute :iam_instance_profile,  :aliases => 'IamInstanceProfile'
        attribute :image_id,              :aliases => 'ImageId'
        #attribute :instance_monitoring,   :aliases => 'InstanceMonitoring'
        attribute :instance_monitoring,   :aliases => 'InstanceMonitoring', :squash => 'Enabled'
        attribute :instance_type,         :aliases => 'InstanceType'
        attribute :kernel_id,             :aliases => 'KernelId'
        attribute :key_name,              :aliases => 'KeyName'
        attribute :ramdisk_id,            :aliases => 'RamdiskId'
        attribute :security_groups,       :aliases => 'SecurityGroups'
        attribute :user_data,             :aliases => 'UserData'
        attribute :spot_price,            :aliases => 'SpotPrice'


        register_resource :launch_configuration, RESOURCES_AUTOSCALE

        # Only keeping a few properties, simplest define keeps.
        @keeps = /^id$/


        def self.persistent_type()
        	::LaunchConfiguration
        end

        def create(service)
            create_attribs = self.attribs[:attributes]
            configuration  = service.configurations.create(create_attribs)
        	return configuration
        end

        def destroy(service)
        	destroy_attribs = self.attribs
        	if @id
          	   configuration = service.configurations.destroy(destroy_attribs)
        	else
          	   puts "No ID set, cannot delete."
        	end
        	return configuration
        end
        
    end
  end
end
