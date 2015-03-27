module TestChamber
  module Random
    extend self

    def cid
      "#{chars(1)}#{digits(4)}"
    end

    def chars(len=2)
      ('a'..'z').to_a.shuffle.first(len).join
    end

    def digits(len=2)
      ('0'..'9').to_a.shuffle.first(len).join
    end
  end
end
