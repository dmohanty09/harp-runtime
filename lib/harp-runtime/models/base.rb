require 'securerandom'

# Represents a harp script.
class HarpScript
  include DataMapper::Resource
  property :id, String, :key => true

  property :location, String, :length => 255, :required => true
  property :version, String, :required => true
  property :content, Text, :required => true

  has n, :harp_resources
  has n, :harp_plays, :through => Resource
end

# Represents a single execution of a Harp script.
class HarpPlay
  include DataMapper::Resource
  property :id, Serial

  property :location, String, :length => 255, :required => true
  property :played_at, DateTime
  property :status, String

  # a Harp play may consist of multiple scripts, through composition
  has n, :harp_scripts, :through => Resource
  has n, :harp_resources, :through => :harp_scripts
end

# An atomic unit to create/destroy.
class HarpResource
  attr_accessor :live_resource

  include DataMapper::Resource
  belongs_to :harp_script, :key => true
  property :id, String, :key => true, :required => true

  property :name, String
  property :description, String
  property :state, String
  property :type, Discriminator
  property :output_token, String
  property :value, Text


  @live_resource

  def self.auto_id
    SecureRandom.urlsafe_base64(16)
  end

  def output?(args={})
    if !live_resource
      return nil
    end
    return live_resource.output_token(args)
  end

  def make_output_token(args={})
    self.output_token = live_resource.output_token(args)
  end

end
