module TestChamber::Convertor
  module Compound
    class Base 
      include Capybara::DSL

      def initialize(ordinal, module_ordinal)
        @ordinal = ordinal
        @module_ordinal = module_ordinal
      end

      def do_conversion!(*args)
        raise NotImplementedError
      end

    end
  end
end
