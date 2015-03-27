module TestChamber
  # Mixin for caching objects in memory to speed up specs
  module ObjectCache

    def self.included(base)
      base.class_eval do
        alias_method_chain :create!, :cache
      end
    end

    # Retrieve object from cache and set @id.
    def object_from_cache
      obj = TestChamber.object_cache[sha]
      @id = obj.id
      obj
    end

    # Memoized SHA2 hash of @raw_opts (no creator) or cache_key (w/ creator)
    def sha
      @sha ||= @raw_opts ? Digest::SHA2.hexdigest(@raw_opts.to_s) : cache_key
    end

    # Checks Test Chamber object cache for sha of @raw_opts/cache_key
    def cached?
      TestChamber.object_cache.has_key?(sha)
    end

    # Add object to cache
    def cache_object
      TestChamber.object_cache[sha] = self
    end

    def create_with_cache!
      if (cached? && !@options[:ignore_cache])
        object_from_cache
      else
        create_without_cache!
      end
    end
  end
end
