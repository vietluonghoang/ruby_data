##
# When an appium spec is run, we want to make sure that the appium definition cascades
# from the highest level it is called at, but nowhere else. This spec checks that
# the current_driver matches what it should be.
#
# A note in case someone ever wants to delete this:
#
# This spec looks trivial but it tests spec_helper code that includes side effects
# in multiple, nested sets of before hooks. It's not trivial. Move along.
#
# A note to the person thinking 'I can DRY this up by being clever':
#
# Honestly, this is too complicated to understand already. Is your DRYing going
# to make it harder to understand what's going on here? Then move along.
#
# The code this exercises is in the spec_helper RSpec.configure block's global
# before :context hook.
##

require 'spec_helper'

describe "An spec tagged ':appium'", :appium, :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  it 'should use appium as the driver' do
    expect(Capybara.current_driver).to eq(driver)
  end
end

describe "A spec not tagged ':appium'", :unit do
  it 'should use selenium as the driver' do
    expect(Capybara.current_driver).to eq(:selenium)
  end
end

describe "A spec tagged ':appium'", :appium, :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with an appium context', :appium do
    it 'should use appium as the driver' do
      expect(Capybara.current_driver).to eq(driver)
    end
  end
end

describe "A spec not tagged ':appium'", :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with an appium context', :appium do
    it 'should use appium as the driver' do
      expect(Capybara.current_driver).to eq(driver)
    end
  end
end

describe 'A spec', :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with a non-appum context' do
    it 'should use selenium as the driver' do
      expect(Capybara.current_driver).to eq(:selenium)
    end
  end

  context 'with an appium context', :appium do
    it 'should use appium as the driver' do
      expect(Capybara.current_driver).to eq(driver)
    end
  end
end

describe 'A spec', :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with multiple contexts' do
    context 'with an appium context', :appium do
      it 'should use appium in the appium context' do
        expect(Capybara.current_driver).to eq(driver)
      end
    end

    context 'with a non-appium context' do
      it 'should not use appium in the non-appium context' do
        expect(Capybara.current_driver).to eq(:selenium)
      end
    end
  end
end

describe 'A spec', :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with a context with appium and non-appium specs' do
    it 'should use appium for the appium spec', :appium do
      expect(Capybara.current_driver).to eq(driver)
    end

    it 'should use selenium for the selenium spec' do
      expect(Capybara.current_driver).to eq(:selenium)
    end
  end
end

# This is where it gets weird. Just remember 'describe' and 'context' are aliased.
# Since we're testing hooks, convention is a 'describe'
describe 'An appium spec', :appium, :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with before :example hooks' do
    describe 'should use appium in before :example hooks' do
      before :example do
        expect(Capybara.current_driver).to eq(driver)
      end

      it 'still uses appium in the example after before :example hooks' do
        expect(Capybara.current_driver).to eq(driver)
      end
    end
  end

  context 'with before :context hooks' do
    describe 'should use appium in before :context hooks' do
      before :context do
        driver = TC::Config[:appium][:os].downcase.to_sym
        expect(Capybara.current_driver).to eq(driver)
      end

      it 'still uses appium in the example after before :example hooks' do
        expect(Capybara.current_driver).to eq(driver)
      end
    end
  end

  context 'with before :context and before :example hooks' do
    describe 'should use appium in both hooks' do
      before :context do
        driver = TC::Config[:appium][:os].downcase.to_sym
        expect(Capybara.current_driver).to eq(driver)
      end

      before :example do
        expect(Capybara.current_driver).to eq(driver)
      end

      it 'still uses appium in the example after both hooks' do
        expect(Capybara.current_driver).to eq(driver)
      end
    end
  end
end

describe 'A spec', :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with a non-appium context' do
    describe 'before :example hooks use selenium' do
      before :example do
        expect(Capybara.current_driver).to eq(:selenium)
      end

      it {}
    end

    describe 'before :context hooks use selenium' do
      before :context do
        expect(Capybara.current_driver).to eq(:selenium)
      end

      it {}
    end
  end

  context 'with an appium context', :appium do
    describe 'before :example hooks use appium' do
      before :example do
        expect(Capybara.current_driver).to eq(driver)
      end

      it {}
    end

    describe 'before :context hooks use appium' do
      before :context do
        driver = TC::Config[:appium][:os].downcase.to_sym
        expect(Capybara.current_driver).to eq(driver)
      end

      it {}
    end
  end
end

describe 'A spec', :unit do
  let(:driver) { TC::Config[:appium][:os].downcase.to_sym }

  context 'with an appium context', :appium, :unit do
    it 'should use appium as the driver' do
      expect(Capybara.current_driver).to eq(driver)
    end
  end

  it 'uses selenium after an appium context', :unit do
    expect(Capybara.current_driver).to eq(:selenium)
  end
end
