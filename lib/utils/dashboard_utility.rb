module TestChamber
  module DashboardUtility
    module DSL
      def select_item(item, options={})
        begin
          if item
            from = options.delete(:from) if options.has_key?(:from)

            page.find(from, visible: false).click
            page.all("#{from}+div ul li", visible: false).each do |opt|
              if opt.text==item && opt.visible?
                opt.click
                break
              end
            end
            if page.find(from, visible: false).text != item.to_s
              select_item(item, {:from => from})
            end
          end
        rescue Selenium::WebDriver::Error::ElementNotVisibleError => e
          select_item(item, {:from => from})
        end
      end
    end
  end
end