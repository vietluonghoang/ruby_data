require 'active_support/core_ext/hash/indifferent_access'
module TestChamber
  # lifted directly from TJS so that we can decrypt URL parameters for offers
  # on the offerwall
  class SymmetricCrypto
    def self.encrypt(text, key, cipher_type = 'AES256')
      aes(:encrypt, text, key, cipher_type)
    end

    def self.decrypt(crypted, key, cipher_type = 'AES256')
      aes(:decrypt, crypted, key, cipher_type)
    end

    private
    def self.aes(direction, message, key, cipher_type = 'AES256')
      cipher = OpenSSL::Cipher.new(cipher_type)
      direction == :encrypt ? cipher.encrypt : cipher.decrypt
      cipher.key = key
      cipher.update(message) + cipher.final
    end
  end

  # lifted directly from TJS so that we can decrypt URL parameters for offers
  # on the offerwall
  class ObjectEncryptor < SymmetricCrypto
    def self.encrypt(object, use_json = false, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
      serialized_object = use_json ? ActiveSupport::JSON.encode(object) : Marshal.dump(object)
      super(serialized_object, key, cipher_type).unpack("H*").first
    end

    def self.b64_encrypt(object, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
      res = SymmetricCrypto.encrypt(Marshal.dump(object), key, cipher_type)
      [res].pack("m0*").tr('+/','-_').gsub("\n",'')
    end

    def self.decrypt(crypted, use_json = false, key = SYMMETRIC_CRYPTO_SECRET)
      begin
        packed = [crypted].pack("H*")
        serialized_object = super(packed, key)
        if use_json
          ActiveSupport::JSON.decode(serialized_object)
        else
          Marshal.load(serialized_object)
        end
      rescue
        packed = crypted.tr('_-','/+').unpack("m0*").first
        serialized_object = super(packed, key)
        if use_json
          ActiveSupport::JSON.decode(serialized_object)
        else
          Marshal.load(serialized_object)
        end
      end
    end

    def self.encrypt_url(url, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
      uri = URI.parse(url)
      uri.query = "data=#{encrypt(make_params(uri))}"
      uri.to_s
    end

    def self.b64_encrypt_url(url, key = SYMMETRIC_CRYPTO_SECRET, cipher_type = 'AES256')
      uri = URI.parse(url)
      uri.query = "data=#{b64_encrypt(make_params(uri))}"
      uri.to_s
    end

    private

    def self.make_params(url)
      params = CGI.parse(url.query)
      params.each { |k, v| params[k] = v.first }
    end

  end
end
