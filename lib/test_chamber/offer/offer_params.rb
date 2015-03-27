module TestChamber

  ## OfferParams module
  ##
  ## Include this module in an offer class to dictate the parameters sent
  ## to TJS when displaying and converting offers.  More actions could easily
  ## be added as well as additional object types.
  ##
  ## See config/offer_params/Readme.md for more information
  module OfferParams

    def params_for(group, action)
      ## TestChamber::Configs grouped in separate files using pluralized class name as
      ## key.
      ##    For example:
      ## generic_offers -> generic_offer -> {params -> {}}, {static_params -> {}}
      ## generic_offers -> device        -> {params -> {}}, {static_params -> {}}
      ## video_offers   -> video_offer   -> {params -> {}}, {static_params -> {}}
      ## video_offers   -> device        -> {params -> {}}, {static_params -> {}}
      ## etc...
      raise "TestChamber::Config group #{group} does not exist" if TestChamber::Config[group].nil?

      request_properties = TestChamber::Config[group][offer_params_type.to_sym][action.to_sym]

      map_params(request_properties).merge(request_properties[:static_params] || {})
    end

    private
      ## Map parameter names to values using properties hash
      ## properties - hash object, likely loaded from YML params file,
      ##    format: {params => {tjs_param_name => test_chamber_param_name, ...}, defaults => {tjs_param_name => value } }
      ## Populates and returns params hash, will raise error if a parameter is not found on
      ## the current object.
      def map_params(param_properties)
        {}.tap do |params|
          param_properties[:params].each do |key, value|
            ## if the entry has a non-nil value, use it as the property attrib. name
            ## otherwise use the key
            attribute_name = value || key
            begin
              if self.respond_to?(:attributes)
                params[key] = self.attributes[attribute_name]
              else
                # Temporary backwards compatability support for objects using this but not the Properties mixin
                params[key] = self.instance_variable_get("@#{attribute_name}".to_sym)
              end
            rescue => e
              raise "Exception in map_params: #{e}"
            end
          end
        end
      end

      # Snake case the current object without any namespace
      # Specialize this method to override an offer's parameter type
      # e.g. MraidOffer.offer_params_type returns 'generic_offer'
      def offer_params_type
        self.class.name.demodulize.underscore
      end

  end

end
