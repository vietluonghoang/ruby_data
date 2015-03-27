module TestChamber
  class Currency
    include Capybara::DSL

    attr_accessor :rev_share_override

    def initialize(app, options = {})
      defaults = {
        id: nil,
        rev_share_override: 0.0
      }

      options = defaults.merge(options)

      @rev_share_override = options[:rev_share_override]

      if options[:autocreated]
        visit "#{TestChamber.target_url}/dashboard/apps/#{app.id}/currencies/#{app.id}"
        fill_in('currency[rev_share_override]', with: @rev_share_override)
        click_button('Update Currency')
      else
        #todo make this so less hacky
      end
    end
  end
end
