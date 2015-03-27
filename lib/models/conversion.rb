module TestChamber
  module Models
    class Conversion < ActiveRecord::Base
      include MonetaryValue::Support::ActiveRecord
      self.primary_key = :id

      has_many :conversion_revenue_shares
      has_one  :rev_share_input_set

      composed_of_money :monetary_advertiser_amount, :value_field => 'advertiser_amount', :exponent_field => 'advertiser_amount_exponent'
      composed_of_money :monetary_publisher_amount, :value_field => 'publisher_amount', :exponent_field => 'advertiser_amount_exponent'
      composed_of_money :monetary_tapjoy_amount,  :value_field => 'tapjoy_amount', :exponent_field => 'tapjoy_amount_exponent'

      SHARE_TYPES = ['advertiser_amount', 'publisher_amount', 'tapjoy_amount', 'spend_share']

      def offer_conversion(offer_id)
        Conversion.find(:all, :conditions => { :advertiser_offer_id => [offer_id] } )
      end

      def conversion_count(offer_id)
        offer_conversion(offer_id).count
      end

      def advertiser_amount(offer_id)
        offer_conversion(offer_id).inject (0) { |sum, conversion| sum + conversion.publisher_amount }
      end

      def rev_share_for(share_type)
        conversion_revenue_shares.where(share_type: share_type).first
      end

      def rev_share_amounts
        amounts = {
          advertiser_amount: monetary_advertiser_amount.to_f,
          publisher_amount: monetary_publisher_amount.to_f,
          tapjoy_amount: monetary_tapjoy_amount.to_f,
          spend_share: spend_share.to_f
        }

        # we need to compare advertiser_amount and publisher_amount with their  
        # respective share_types, to make sure they still match.
        conversion_revenue_shares.each do |share|

          share_type = share.share_type.to_sym
          share_amount = share.monetary_amount.to_f

          if amounts.include? share_type
            if amounts[share_type] != share_amount
              raise "ConversionRevenueShare #{share_type} did not equal #{share_type} from Conversion. These values should always match; did you change the revshare calculator or Conversion schema? If so, you may need to update the TestChamber Conversion model."
            end
            next
          end

          amounts["share_#{share_type}".to_sym] = share_amount
        end
        amounts
      end
    end
  end
end
