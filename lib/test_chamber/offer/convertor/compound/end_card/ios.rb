module TestChamber::Convertor
  module Compound
    module IOS
      class EndCard < TestChamber::Convertor::Compound::Base

        def do_conversion!(*args)
          Util.wait_for(30) do
            # wait until the js has all loaded and added click handlers to the cta 
            page.evaluate_script("document.readyState;") == 'complete'
          end

          cta_button = page.all(:class, 'cta')[@module_ordinal]
          cta_button.click
        end
      end
    end
  end
end
