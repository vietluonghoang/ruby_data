module TestChamber::Creator
  class Survey
    module UiV1
      class CreatorNotSupported < StandardError; end

      def create!
        raise CreatorNotSupported, "Warning: Creation of Survey offers currently not supported."
      end
    end
  end
end
