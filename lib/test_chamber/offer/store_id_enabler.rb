module TestChamber::Offer::StoreIdEnabler
  # Offers that have apps associated with them (install, PPE, etc) need to have the app store metadata
  # set on them. The issue here is that this is done by communicating directly with the app store when
  # an app is enabled and we don't do that on tiab. This puts the app store metadata on to the app for
  # this offer so that the enable validations work correctly.
  #
  # Any time we have to touch the TIAB database it is because there was some piece of behavior that there
  # was no way to access for outside the TIAB through UI's or API's. This is always suboptimal but in some
  # cases its necessary.
  #
  # In this case the AppMetadata stuff is the app store information for a live app
  # in the appstore. Since we never put test offers into the app store we have to fake out the
  # metadata. So far it hasn't been relevant what the metadata actually is so we just assign the
  # first one to the apps metadata and set up the correct relationships to make it look like
  # this offer is for an app live in the app store
  #
  # The order of operations here has been meticulously worked out to make ActiveRecord happy
  def populate_store_id
    # NOTE: there is no implemented PUT API for this controller yet. This would be better
    # but instead we're setting these in populate_store_id for now. When there is an PUT
    # controller for this api_endpoint we should use this instead
    #        update!(tapjoy_enabled: true, user_enabled: true)

    metadata = TestChamber::Models::AppMetadata.first
    offer = TestChamber::Models::Offer.find(id)
    if app_id
      app = TestChamber::Models::App.find(app_id)
    else
      app = offer.app
    end

    app.app_metadatas = [metadata]

    amm_id = app.app_metadata_mappings.first.id
    
    amm = TestChamber::Models::AppMetadataMapping.find(amm_id)
    amm.is_primary = true
    amm.save!
    
    metadata.offers << offer
    metadata.save!
    app.save!

    # It needs to use offer model inorder to make it tapjoy_enabled, ppi offer requires a valid store id from dashboard UI; so below we are manually enabling it in database.

    # it should be possible to do this through the API but for install offers we don't create them in the api
    # if we are using a new App's default offer, because its created by default. There is an
    # PUT REST API for install offers but you can only set bid and enabled fields with it.
    # However it does clear the cache. So we set tapjoy_enabled with the db, and enabled with the UI which sets the field and
    # clears the cache so the cache gets the tapjoy_enabled change. Jazz hands.
    offer.tapjoy_enabled = true
    offer.save!
    authenticated_request(:put, "#{TestChamber::target_url}/api/client/ads/#{id}", payload: {enabled: true})
  end
end
