module TestChamber
  # Bare object used as a "blank" default. If this class is assigned as a default the property will be skipped over when
  # adding attributes unless a value is explicitly provided (meaning the property will not exist as a key in the
  # properties object).
  class NoDefaultValue < BasicObject; end

  # Thrown when a given property has not been defined.
  class PropertyNotSupported < ArgumentError
    attr_reader :property, :object

    def initialize(property, obj)
      @property = property
      @object   = obj

      msg = "The %s property is not currently supported for %s"
      super(msg % [property, obj.class])
    end
  end

  # Thrown when a property is redefined without forcing it.
  class DuplicateProperty < ArgumentError
    attr_reader :property, :object

    def initialize(property, obj)
      @property = property
      @object   = obj

      msg = "Duplicate property '%s' for %s. Use property! or pass overwrite: true to ignore this."
      super(msg % [property, obj])
    end
  end

  # Thrown when `Properties.class_for` can't find a valid candidate class for the given object and action.
  class PropertiesForActionNotDefined < RuntimeError
    def initialize(klass_name)
      super("No supported action properties for offer of type #{klass_name}")
    end
  end

  # A Properties class is used to define the data structure of a Test Chamber object (such as `TestChamber::Offer`).
  # It provides mechanisms for defining supported properties with static and computed default values. Validations of
  # these properties are also available, allowing us to short-circuit out of a spec before going through the entire
  # Offer or App creation process.
  #
  # @see TestChamber::OfferProperties
  # @see TestChamber::OfferProperties::ActionApi
  class Properties < ActiveSupport::HashWithIndifferentAccess
    class <<self
      # Given a TestChamber object, attempt to find a properties class.
      #
      # With an input object of type `TestChamber::Offer::Video` and an action of `:ui_v1` we would expect to find a
      # properties class named `TestChamber::OfferProperties::VideoUiV1`. If the candidate action `:ui_v1` cannot be
      # found we look through all available actions as specified in `TestChamber::ActionDecorator.actions` until either
      # a candidate is found or we raise a `PropertiesForActionNotDefined` error.
      #
      # @param object [Object] The TestChamber object we need a properties class for
      # @param action [Symbol] An action (such as the default `:api`) from the `ActionDecorator.actions` list.
      # @return [Properties] A subclass (not instantiated) of `Properties` for the given object and action.
      # @raise [PropertiesForActionNotDefined]
      def class_for(object, action = :api)
        klass_name = object.class.to_s.split('::')
        base_klass = klass_name[1]
        act_klass  = klass_name[2]

        actions = TestChamber::ActionDecorator.actions.dup
        actions = ([actions.delete(action)] + actions).compact # Tack the explict action on front

        actions.each do |action|
          const = "#{base_klass}Properties::#{act_klass}#{action.to_s.camelcase}"
          return TestChamber.const_get(const) if TestChamber.const_defined?(const)
        end

        raise PropertiesForActionNotDefined.new(klass_name)
      end

      # A list of properties supported for this class. Use the `.property` method to add new ones.
      def properties
        @properties ||= Hash.new
      end

      # A list of property keys that are considered settings and shouldn't be used when comparing objects.
      def settings
        @settings ||= Set.new
      end

      # Check if a property is supported by this class.
      #
      # @param property [Symbol] The name of the property to check.
      def supported?(property)
        self.properties.key?(property.to_sym)
      end

      # Check if a property is considered a setting.
      #
      # @param property [Symbol] The name of the property to check.
      def setting?(property)
        self.settings.include?(property.to_sym)
      end

      # Add a new property with an optional default value. If a property of the same name is already defined the default
      # behavior is to raise a `DuplicateProperty` error. To set a new default on an already defined property either use
      # the `.property!` method or set the `overwrite` argument to `true`.
      #
      # @param property [Symbol] The name of the property.
      # @param default [Object] The default value for this property. If a lambda is used here it will be evaluated when
      #   the object is initialized.
      # @option overwrite [boolean] Set this to `true` to overwrite an already defined property.
      # @return self for chaining
      def property(property, default=NoDefaultValue, overwrite: false)
        property = property.to_sym

        if !overwrite && self.properties.key?(property)
          raise DuplicateProperty.new(property, self)
        end

        self.properties[property] = default
        define_method(property) { self[property] }
        define_method("#{property}=") { |val| self[property] = val }

        __push_property_down_chain(property, default)

        # For chaining
        return self
      end

      # Forcefully define a property, even if it already exists.
      #
      # @see TestChamber::Properties.property
      def property!(property, default=NoDefaultValue)
        property(property, default, overwrite: true)
      end

      # A setting is similar to a property in usage, but will not be check when comparing against another instance of a
      # Properties class.
      #
      # @see TestChamber::Properties.property
      def setting(setting, default=NoDefaultValue)
        self.settings.add(setting.to_sym)
        property(setting, default, overwrite: true)
      end

      # Returns a new instance of the given attributes with undefined properties removed.
      #
      # @param attributes [Hash] A set of attributes that will be stripped.
      # @return [Hash] The stripped set of attributes.
      def conform_to(attributes)
        attributes.select { |prop| supported?(prop) }
      end

      private
      # Track the classes inheriting from us so we can keep updating properties down the chain.
      def inherited(subclass)
        __property_subclasses.push(subclass)

        self.properties.each do |property, default|
          __push_property_to_subclass(subclass, property, default)
        end
      end

      def __push_property_down_chain(property, default)
        __property_subclasses.each do |subclass|
          __push_property_to_subclass(subclass, property, default)
        end
      end
      def __push_property_to_subclass(subclass, property, default)
        if self.setting?(property)
          subclass.setting(property, default)
        else
          subclass.property(property, default)
        end
      end

      def __property_subclasses
        @__property_subclasses ||= Array.new
      end
    end

    # @!group Settings

    # Action used for object creation
    # @see TestChamber::ActionDecorator.actions
    # @!attribute create_with
    setting :create_with, :api

    # Module to use for object creation
    # @!attribute creator_module
    setting :creator_module, NoDefaultValue

    # Action used when editing objects
    # @see TestChamber::ActionDecorator.actions
    # @!attribute edit_with
    setting :edit_with, :api

    # Module to use when editing objects
    # @!attribute editor_module
    setting :editor_module, NoDefaultValue

    # Set this to use a specific Properties class
    # @see InstanceMethods#wrap_attributes
    # @!attribute properties_class
    setting :properties_class, NoDefaultValue

    # Automatic validation of an object after creation or editing
    # @!attribute validate
    setting :validate, true

    # @!endgroup

    # Take an input set of attributes, apply defaults if necessary, and assert they are all supported.
    #
    # @param attributes [Hash] An optional hash of attributes. All keys must be supported (by defining it as a
    #   property).
    # @param ignore_defaults [boolean] If true, default values for each property will be ignored.
    def initialize(attributes={}, ignore_defaults=false)
      attributes = self.class.properties.merge(attributes) unless ignore_defaults

      attributes.each do |property, value|
        assert_supported!(property)

        # Don't continue for blank default properties. Means `#key?(property)` will be `false` for this property.
        next if value == NoDefaultValue

        self[property] = default_for(property, value)
      end
    end

    # Check if a property is supported by this class.
    #
    # @param property [Symbol] The name of the property to check.
    # @see Testchamber::Properties.supported?
    def supported?(property)
      self.class.supported?(property)
    end

    # Check if a property is considered a setting by this class.
    #
    # @param property [Symbol] The name of the property to check.
    # @see Testchamber::Properties.setting?
    def setting?(property)
      self.class.setting?(property)
    end

    # Check for the support of a given property and raise a `PropertyNotSupported` error if it's not.
    #
    # @param property [Symbol] The name of the property to check.
    # @raise TestChamber::PropertyNotSupported
    # @see Testchamber::Properties.supported?
    def assert_supported!(property)
      unless supported?(property)
        raise PropertyNotSupported.new(property, self)
      end
    end

    # Access a property with fallback to the default value if it is blank.
    #
    # @param property [Symbol] The name of the property to get.
    # @see TestChamber::Properties#default_for
    def fetch_with_default(property)
      if self.key?(property)
        return self[property]
      else
        return default_for(property)
      end
    end

    # Get the default value of a property. If a second argument is given pretend it is the default. We support this
    # optional second argument so the initializer can use this when setting up the instance (for the arity check).
    #
    # @param property [Symbol] The name of the property to get.
    # @param value [Object] An optional custom default value.
    def default_for(property, *args)
      if args.empty?
        value = self.class.properties[property.to_sym]
      else
        value = args.first
      end

      arity = value.is_a?(Proc) && value.arity
      case arity
      when 0 then value.call
      when 1 then value.call(self)
      else value
      end
    end

    def diff(other)
      Array.new.tap do |diff|
        self.each do |key, value|
          next if setting?(key)
          if value != other[key]
            diff << [key, value, other[key]]
          end
        end
      end
    end

    # Include this module in any object to expose helper methods around managing and loading properties.
    module InstanceMethods
      attr_reader :attributes

      # Assign a Hash or Properties instance as the attributes for this object.
      #
      # @param attributes [Hash, Properties] The set of attributes to use
      # @see TestChamber::Properties::InstanceMethods#wrap_attributes
      def attributes=(attributes = {})
        @attributes = self.wrap_attributes(attributes)
      end

      # These currently must exist to override the title method exposed by `Capybara::DSL`.
      # TODO figure out a way to not require this (perhaps strip any Capybara::DSL methods after wrapping?)
      def title; self.attributes.title; end
      def title=(val); self.attributes.title = val; end

      # Convenience method to handle wrapping a Hash in the correct `TestChamber::Properties` subclass. If the input is
      # already an instance of `TestChamber::Properties` we skip any wrapping. If you wish to use a specific Properties
      # class you can provide a `:properties_class` key in the input hash. Otherwise `TestChamber::Properties.class_for`
      # will be used.
      #
      # @param attributes [Hash, Properties]
      # @param action_key [Symbol] The key on the input hash that contains the action for class loading.
      # @option [Symbol] :default_action Use this action if the action_key does not exist on the input hash.
      # @option [boolean] :ignore_defaults If true, property defaults will be ignored when instantiating the class.
      # @see TestChamber::Properties.class_for
      def wrap_attributes(attributes, action_key=:create_with,
                          default_action: :api,
                          ignore_defaults: false)
        unless attributes.is_a?(TestChamber::Properties)
          # Create a properties class using offer type and create method. If
          # properties class does not exist for the method, Properties will
          # attempt to find a supported properties class for this offer type
          properties_class = attributes.delete(:properties_class) do
            action = attributes.fetch(action_key, default_action)
            TestChamber::Properties.class_for(self, action)
          end

          attributes = properties_class.new(attributes, ignore_defaults)
        end

        return attributes
      end

      # Allow accessing and setting properties through methods. For example, if you have a property `:foo` and include
      # this mixin you will be able to call `obj.foo` and get the value or `obj.foo = value` to set it.
      def method_missing_with_properties(method, *args)
        property = method.to_s.gsub(/=$/, '').to_sym

        if attributes.present? && attributes.supported?(property)
          if args.empty?
            return attributes[property]
          else
            return attributes[property] = args.first
          end
        else
          method_missing_without_properties(method, *args)
        end
      end
      alias_method_chain :method_missing, :properties
    end
  end
end
