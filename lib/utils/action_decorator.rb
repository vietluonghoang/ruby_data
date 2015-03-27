module TestChamber
  module ActionDecorator

    # Supported actions, used when locating a decorator module
    def self.actions
      @actions ||= [:api, :ui_v1, :ui_v2]
    end

    # Decorate an object using the supplied decorator and action.  This will locate a module matching the decorator
    # and action name, and mix the module into the provided object.  This works by searching for a constant following
    # the pattern - TestChamber::#{decorator}::#{object.class}::#{action}
    # @param (Object) object The instantiated object to decorate
    # @param (Symbol) action The action which is used with the decorator, default is :api
    # @param (Symbol,String) decorator The type of decorator to use (Creator, Editor...)
    # @param (Constant) action_module optional Use this to explicitly specify the mixin used to decorate the object
    # @param (Boolean) overwrite re-decorate the object if it has already been decorated, default is false
    def self.decorate(object: , action: nil, decorator: nil, action_module: nil, overwrite: false)

      # check if action was specified and don't log the warning about missing creation methods unless someone specifically asked for one we don't have
      using_default_action = action.nil?
      action ||= :api

      raise "Action must be one of #{actions}, received: #{action}" unless actions.include?(action)
      raise 'Decorator is required unless action_module is specified' if decorator.nil? && action_module.nil?
      included_module_ivar = :"@include_#{decorator}_module"
      return true if object.instance_variable_get(included_module_ivar ) && !overwrite

      if action_module
        object.extend(action_module)
      else
        try_actions = actions.clone
        try_action = try_actions.delete(action)
        base_name = object.class.name.demodulize
        action_module_name = "TestChamber::#{decorator.to_s.camelcase}::#{base_name}"
        begin
          module_name = "#{action_module_name}::#{try_action.to_s.camelcase}"
          unless Object.const_defined?(module_name)
            puts "WARNING: The specified method '#{try_action}' for #{object.class.name} which specifies module '#{action_module_name}' was not found. Trying mechanism '#{try_actions.first}'" unless using_default_action
            try_action = try_actions.shift
          end
        end until Object.const_defined?(module_name) || try_actions.empty?

        if Object.const_defined?(module_name)
          object.extend(module_name.constantize)
        else
          raise "Because the action option specified '#{action}' we are looking for, but couldn't find, a module called '#{module_name}' which should contain the logic for this offer. We tried other mechanisms as well but couldn't find one that worked."
        end
      end

      object.instance_variable_set(included_module_ivar, true)
    end

  end
end
