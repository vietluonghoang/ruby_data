module TestChamber
  # include in classes that need to generate titles like Offers, that are unique
  module UniqueName
    def name_datestamp
      Time.now.strftime("%F_%T_%N")
    end
  end
end
