require 'rubygems'

gem 'dm-core', '>=0.10.2'
require 'dm-core'

module DataMapper
  module Userstamp
    module Stamper
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def userstamp_class
          User
        end

        def current_user=(user)
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"] = user
        end
        
        def current_user
          Thread.current["#{self.to_s.downcase}_#{self.object_id}_stamper"]
        end
      end
    end

    def self.userstamp_class
      User
    end

    USERSTAMP_PROPERTIES = {
      :created_by_id => lambda { |r| r.created_by_id = userstamp_class.current_user.id if userstamp_class.current_user && r.new? && r.created_by_id.nil? },
      :updated_by_id => lambda { |r| r.updated_by_id = userstamp_class.current_user.id if userstamp_class.current_user}
    }

    def self.included(model)
      model.before :save, :set_userstamp_properties
    end

    private

    def set_userstamp_properties
      self.class.properties.values_at(*USERSTAMP_PROPERTIES.keys).compact.each do |property|
        USERSTAMP_PROPERTIES[property.name][self]
      end
    end
  end

  DataMapper::Model.append_inclusions Userstamp
end