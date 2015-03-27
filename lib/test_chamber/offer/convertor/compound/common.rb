module TestChamber::Convertor
  module Compound
    module Common 

      def do_compound_conversion!(platform, *args)

        # wait for the html to be displayed
        page.find(:class, 'modules')

        ordinal = 0
        module_ordinals = {}
        module_ordinals.default = 0
        conversion_modules = page.all(:class, 'module').map do |element|
          # each compound module will look something like this
          #   <div class="module video-module" id="module0">
          #    ...
          #   </div>
          #
          # module type will be derived like this
          #   class='module video-module' => Video 
          #   class='module end-card-module' => EndCard 
          module_type = element[:class].split[1].sub('-module', '').split('-').map { |w| w.capitalize }.join

          clazz = "TestChamber::Convertor::Compound::#{platform}::#{module_type}".constantize
          conversion_module = clazz.new(ordinal, module_ordinals[module_type]) 

          ordinal += 1
          module_ordinals[module_type] += 1

          conversion_module
        end

        conversion_modules.each do |c|
          c.do_conversion!(args)
        end

      end
    end
  end
end
