module TestChamber
  module Models
    class Partner < ActiveRecord::Base
      include MonetaryValue::Support::ActiveRecord

      composed_of_money :monetary_balance, :value_field => 'balance', :exponent_field => 'balance_exponent'
      composed_of_money :monetary_pending_earnings, :value_field => 'pending_earnings', :exponent_field => 'pending_earnings_exponent'
      composed_of_money :monetary_next_payout_amount, :value_field => 'next_payout_amount', :exponent_field => 'next_payout_amount_exponent'
      composed_of_money :monetary_payout_threshold, :value_field => 'payout_threshold', :exponent_field => 'payout_threshold_exponent'

      self.primary_key = :id

      json_set_field :promoted_offers

      has_many :offer_discounts
      has_many :partner_assignments
      has_many :users, :through => :partner_assignments


      def set_reseller(reseller_id)
        self.reseller_id = reseller_id
        self.save!
      end
    end
  end
end
