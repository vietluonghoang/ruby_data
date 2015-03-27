module TestChamber

  # Convenience wrapper for using Chosen select boxes
  # Found this here https://gist.github.com/thijsc/1391107
  module SelectFromChosen

    def single_nosearch_chosen_select(item_text, options)
      field = options[:from]
      section = page.driver.find_xpath("//select[@name='#{field}']/..").first
      section.find_css(".chosen-container-single-nosearch").first.click()
      options = page.driver.find_xpath("//select[@name='#{field}']/..//div[@class='chosen-drop']//li")
      options.select {|e| e.all_text == item_text && e.visible? }.first.click
    end

    # #chosen_select behaves similarly to Capybara's #select
    # chosen_select('Achievement', :from => 'context')
    # will look in the 'context' select box for an option whose text includes 'Achievement.' Once it has the
    #   value of that option, it will set the select box to that value. Note that this does not result in the UI
    #   updating, as we are not actually triggering the change event.
    #
    # multi-select chosen boxes will require a different method.
    def chosen_select(item_text, options)
      field = options[:from]
      option_value = page.evaluate_script "$(\"select[name='#{field}'] option\").filter(function(){return $(this).text() == '#{item_text}'}).val()"
      page.execute_script("$(\"select[name='#{field}']\").val('#{option_value}')")
      #.trigger("chosen:updated")
      raise "invalid option #{item_text} provided for #{field} chosen select" unless page.evaluate_script("$(\"select[name='#{field}']\").val()") == option_value
      true
    end

    def chosen_select_multiple(item_list, options)
      raise "item_list needs to be an array" unless item_list.kind_of?(Array) || item_list.kind_of?(Set)
      field = options[:from]
      item_ids = item_list.map{ | item | page.evaluate_script "$(\"select[name='#{field}'] option:contains('#{item}')\").val()" }
      page.execute_script("$(\"select[name='#{field}']\").val(#{item_ids})")
      set_ids = page.evaluate_script("$(\"select[name='#{field}']\").val()")
      unless (set_ids - item_ids).empty?
        raise "invalid option #{item_list} provided for #{field} chosen select"
      end
    end

    # The values
    def multi_chosen_field_values(field)
      multi_chosen_field_elements(field).map { |ele| ele.text }
    end

    def multi_chosen_field_elements(field)
      find(:css, "##{field}_chzn").all(:css, 'li.search-choice span')
    end
  end
end

