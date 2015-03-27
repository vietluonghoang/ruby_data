module TestChamber::Convertor
  module Compound
    module IOS
      def do_conversion!(*args)
        extend TestChamber::Convertor::Compound::Common
        do_compound_conversion!("IOS", args)
      end
    end
  end
end
