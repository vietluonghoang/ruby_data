module TestChamber::Convertor
  module Compound
    module Android 
      def do_conversion!(*args)
        extend TestChamber::Convertor::Compound::Common
        do_compound_conversion!("Android", args)
      end
    end
  end
end
