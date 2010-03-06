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
    def delegate_belongs_to(association, *args)
      options = args.extract_options!
      belongs_to association, options unless reflect_on_association(association)
      options[:to] = association
      args << options
      delegate_attributes(*args)
    end

    def delegate_has_one(association, *args)
      options = args.extract_options!
      has_one association, options unless reflect_on_association(association)
      options[:to] = association
      args << options
      delegate_attributes(*args)
    end
    
    # belongs_to :contact
    # delegates_attributes_to :contact
    # 
    # has_one :profile
    # delegates_attributes_to :profile
    
    def delegates_attributes_to(association, *args)
      warn "delegates_attributes_to is deprecated use delegate_attributes :to => association syntax"
      options = args.extract_options!
      options[:to] = association
      args << options
      delegate_attributes(*args)
    end
    
    # New syntax
    #
    # has_one :profile
    # delegate_attributes :to => :profile
    def delegate_attributes(*args)
      options = args.extract_options!
      attributes = args
      association = options.delete(:to)
      raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate_attribute :hello, :to => :greeter" unless association
      reflection = reflect_on_association(association)
      raise ArgumentError, "Unknown association #{association}" unless reflection

      reflection.options[:autosave] = true unless reflection.options.has_key?(:autosave)

      if attributes.empty? || attributes.delete(:defaults)
        attributes += default_delegated_attributes_for(reflection)
      end

      attributes.each do |attribute| 
        delegated_attributes.merge!(attribute => association)
        define_delegated_attribute_methods(association, attribute)
      end
    end
    
    alias_method :delegate_attribute,   :delegate_attributes
    alias_method :delegates_attribute,  :delegate_attributes
    alias_method :delegates_attributes, :delegate_attributes
    
    def detect_association_by_attribute(attribute)
      delegated_attributes[normalize_attribute_name(attribute)]
    end
    
    private
    
    def define_delegated_attribute_methods(association, attribute)
      delegate attribute, :to => association, :allow_nil => true
      define_method("#{attribute}=") do |value|
        association_object = send(association) || send("build_#{association}")
        association_object.send("#{attribute}=", value)
      end
      
      ActiveRecord::Dirty::DIRTY_SUFFIXES.each do |suffix|
        define_method("#{attribute}#{suffix}") do
          association_object = send(association) || send("build_#{association}")
          association_object.send("#{attribute}#{suffix}")
        end
      end
    end
    
    def default_delegated_attributes_for(reflection)
      column_names = reflection.klass.column_names
      default_rejected_delegate_columns.each {|column| column_names.delete(column) }
      column_names
    end
    
    # convert multiparameter attribute to normal form 
    # 'published_at(2i)' becomes 'published_at'
    def normalize_attribute_name(attribute)
      attribute.to_s[/^(\w+)(\([0-9]*\w\))?$/, 1]
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
        self.class.delegated_attributes.each do |attribute, association|
          # If an association isn't loaded it hasn't changed at all. So we skip it.
          # If we don't skip it and have mutual delegation beetween 2 models 
          # we get SystemStackError: stack level too deep while trying to load 
          # a chain like user.profile.user.profile.user.profile...
          next unless send("loaded_#{association}?")
          # skip if association object is nil
          next unless association_object = send(association)
          # call private method #changed_attributes
          result.merge! association_object.send(:changed_attributes).slice(attribute)
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
        
    base.class_inheritable_accessor :delegated_attributes
    base.delegated_attributes = HashWithIndifferentAccess.new
  end
end

DelegateBelongsTo = DelegatesAttributesTo unless defined?(DelegateBelongsTo)

ActiveRecord::Base.send :include, DelegatesAttributesTo