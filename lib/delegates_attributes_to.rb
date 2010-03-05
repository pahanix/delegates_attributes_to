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
module DelegatesAttributesTo
  
  module ClassMethods
    ##
    # Creates methods for accessing and setting attributes on an association.  Uses same
    # default list of attributes as delegates_to_association.  

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
      reflection = reflect_on_association(association)
      raise ArgumentError, "Unknown association #{association}" unless reflection

      reflection.options[:autosave] = true unless reflection.options.has_key?(:autosave)

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
    
    def detect_association_by_attribute(attr_name)
      dirty_associations.each do |assoc, attributes|
        return assoc if attributes.include?(attr_name.to_s[/^(\w+)(\([0-9]*[if]\))?$/, 1])
      end
      return nil
    end
    
  end

  module InstanceMethods
    
    private
    
      def assign_multiparameter_attributes_with_delegation(pairs)
        delegated_pairs = {}
        original_pairs  = []
        
        pairs.each do |name, value|
          if assoc = self.class.detect_association_by_attribute(name)
            (delegated_pairs[assoc] ||= {})[name] = value
          else
            original_pairs << [name, value]
          end
        end
        
        delegated_pairs.each do |association, attributes|
          association_object = send(association) || send("build_#{association}")
          association_object.attributes = attributes
        end
        
        assign_multiparameter_attributes_without_delegation(original_pairs)
      end
      
      def changed_attributes
        result = {}
        self.class.dirty_associations.each do |association, attributes|
          # If an association isn't loaded it hasn't changed at all. So we skip it.
          # If we don't skip it and have mutual delegation beetween 2 models 
          # we get SystemStackError: stack level too deep while trying to load 
          # a chain like user.profile.user.profile.user.profile...
          next unless send("loaded_#{association}?")
          association_changed_attributes = send(association).send(:changed_attributes) || {}
          result.merge! association_changed_attributes.slice(*attributes)
        end
        changed_attributes = super
        changed_attributes.merge!(result)
        changed_attributes
      end
  end
  
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
    
    base.alias_method_chain :assign_multiparameter_attributes, :delegation
    
    base.class_inheritable_accessor :default_rejected_delegate_columns
    base.default_rejected_delegate_columns = ['created_at','created_on','updated_at','updated_on','lock_version','type','id','position','parent_id','lft','rgt']
    
    base.class_inheritable_accessor :dirty_associations
    base.dirty_associations = {}
  end
end

DelegateBelongsTo = DelegatesAttributesTo unless defined?(DelegateBelongsTo)

ActiveRecord::Base.send :include, DelegatesAttributesTo