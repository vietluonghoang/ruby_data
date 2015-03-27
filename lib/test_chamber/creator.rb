module TestChamber::Creator
  module InstanceMethods
    CREATION_METHODS = [:api, :ui_v2, :ui_v1]

    def store_options(options, defaults={})
      # always default to :api. If the :create_with option is passed in that will
      # override this below when we set instance_variables for each option
      @create_with = :api

      @raw_opts = options

      unless respond_to?(:option_defaults)
        raise NotImplementedError "The class that includes this module must implement option_defaults method which returns a hash of the defaults for creating the object. All entries in the hash will be stored as instance variables."
      end

      @options = defaults.merge(options)
      @options = option_defaults.merge(@options)

      @options.each { |name, value| instance_variable_set("@#{name}", value) }
    end

  end
end
