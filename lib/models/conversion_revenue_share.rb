module TestChamber
  module Models
    class ConversionRevenueShare < ActiveRecord::Base
      include MonetaryValue::Support::ActiveRecord

      belongs_to :conversion

      composed_of_money :monetary_amount, :value_field => 'amount', :exponent_field => 'amount_exponent'
    end
  end
end
