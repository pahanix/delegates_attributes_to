##
# Creates methods on object which delegate to an association proxy.
# see delegate_belongs_to for two uses
# 
# class User < ActiveRecord::Base; delegate_belongs_to :contact, :firstname; end
# class Contact < ActiveRecord::Base; end
# u = User.first
# u.changed? # => false
# u.firstname = 'Bobby'
# u.changed? # => true
module DelegateBelongsTo
  
  module ClassMethods
    ##
    # Creates methods for accessing and setting attributes on an association.  Uses same
    # default list of attributes as delegates_to_association.  
    # @todo Integrate this with ActiveRecord::Dirty, so if you set a property through one of these setters and then call save on this object, it will save the associated object automatically.
    # delegate_belongs_to :contact
    # delegate_belongs_to :contact, [:defaults]  ## same as above, and useless
    # delegate_belongs_to :contact, [:defaults, :address, :fullname], :class_name => 'VCard'
    ##
    def delegate_belongs_to(association, *attributes)
      options = attributes.extract_options!
      belongs_to association, options unless reflect_on_association(association)
      
      delegates_attributes_to association, *attributes
    end

    def delegate_has_one(association, *attributes)
      options = attributes.extract_options!
      has_one association, options unless reflect_on_association(association)
      
      delegates_attributes_to association, *attributes
    end
    
    # belongs_to :contact
    # delegates_attributes_to :contact
    # 
    # has_one :profile
    # delegates_attributes_to :profile
    
    def delegates_attributes_to(association, *attributes)
      raise ArgumentError, "Unknown association #{association}" unless reflection = reflect_on_association(association)

      if attributes.empty? || attributes.delete(:defaults)
        column_names = reflection.klass.column_names
        default_rejected_delegate_columns.each {|column| column_names.delete(column) }
        attributes += column_names
      end

      attributes.map!(&:to_s)

      dirty_associations.merge!(association => attributes)

      attributes.each do |attribute|
        delegate attribute, :to => association, :allow_nil => true
        define_method("#{attribute}=") do |value|
          send("build_#{association}") unless send(association)
          send(association).send("#{attribute}=", value)
        end
        
        ActiveRecord::Dirty::DIRTY_SUFFIXES.each do |suffix|
          define_method("#{attribute}#{suffix}") do
            send("build_#{association}") unless send(association)
            send(association).send("#{attribute}#{suffix}")
          end
        end
      end
    end
    
  end

  module InstanceMethods
    
    private
    
      def changed_attributes_with_associations
        result = {}
        self.class.dirty_associations.each do |association, attributes|
          association_changed_attributes = send(association).try(:changed_attributes) || {}
          result.merge! association_changed_attributes.slice(*attributes)
        end
        changed_attributes_without_associations.merge!(result)
        changed_attributes_without_associations
      end
  end
  
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
    
    base.class_inheritable_accessor :default_rejected_delegate_columns
    base.default_rejected_delegate_columns = ['created_at','created_on','updated_at','updated_on','lock_version','type','id','position','parent_id','lft','rgt']
    
    base.class_inheritable_accessor :dirty_associations
    base.dirty_associations = {}
    
    base.alias_method_chain :changed_attributes, :associations
  end
end

ActiveRecord::Base.send :include, DelegateBelongsTo