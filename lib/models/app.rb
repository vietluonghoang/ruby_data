module TestChamber
  module Models
    class App < ActiveRecord::Base
      include UuidPrimaryKey
      self.primary_key = :id

      json_set_field :admin_countries_blacklist

      belongs_to :app_metadata
      has_many :app_metadata_mappings
      has_one :primary_app_metadata_mapping, -> { where(is_primary: true)},
              :class_name => 'AppMetadataMapping'
      has_many :app_metadatas, :through => :app_metadata_mappings
      has_one :primary_app_metadata, -> { where("app_metadata_mappings.is_primary = true")},
              :through => :app_metadata_mappings,
              :source => :app_metadata

      has_many :currencies
    end

    # See Offer::Install#pre_enable for an explanation
    class AppMetadataMapping < ActiveRecord::Base
      include UuidPrimaryKey
      self.primary_key = :id

      belongs_to :app
      belongs_to :app_metadata

      validates_presence_of :app, :app_metadata
      validates_uniqueness_of :app_id, :scope => [ :app_metadata_id ], :message => "already has a mapping to this metadata"
    end

    class AppMetadata < ActiveRecord::Base
      include UuidPrimaryKey
      self.primary_key = :id

      def self.table_name
        "app_metadatas"
      end

      json_set_field :countries_blacklist, :screenshots

      has_many :app_metadata_mappings
      has_many :apps, :through => :app_metadata_mappings
      has_many :offers
    end

  end

end
