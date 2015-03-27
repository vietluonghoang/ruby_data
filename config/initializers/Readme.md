Offer parameter files are organized by Group -> Object -> Action -> {params: {}, static_params: {} }
 - Group is the TestChamber::Config key the params will go into, e.g. TestChamber::Config[:generic_offers]
 - Object is the snake cased name of the test_chamber class (no module included), e.g. TestChamber::Config[:generic_offers][:device]
 - Action is the offer action to use these params for, e.g. TestChamber::Config[:generic_offers][:device][:display_offer]
 - params is a dictionary of parameters, where the key is the value sent to TJS, and the value is the name of
    the parameter on the object.  Leave the value empty if both the TJS and test_chamber params have the same
    name.
 - static_params is a dictionary of parameters to send to TJS with a static values.
