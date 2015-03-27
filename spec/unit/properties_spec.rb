require 'spec_helper_fast'
require 'active_support/core_ext/string/inflections'

require 'utils/action_decorator'
require 'utils/random'
require 'test_chamber/properties'

describe TestChamber::Properties, :unit do
  let(:properties_class) { Class.new(described_class) }
  let(:properties) { properties_class.new(attributes) }
  let(:attributes) { Hash.new }

  it { expect(subject).to be_a(ActiveSupport::HashWithIndifferentAccess) }

  context 'supports properties and defaults' do
    before(:each) do
      properties_class.property(:simple)
      properties_class.property(:default_nil, nil)
      properties_class.setting(:default_val, :default)
      properties_class.setting(:default_lazy, -> { :lazy })
    end

    it 'supports default values' do
      expect(properties).not_to have_key(:simple)

      expect(properties).to have_key(:default_nil)
      expect(properties.default_nil).to be_nil

      expect(properties.default_val).to eq(:default)
      expect(properties.default_lazy).to eq(:lazy)
    end

    it 'can force a hash to conform to the defined properties' do
      arguments = {simple: :value, undefined: :value}
      stripped  = properties_class.conform_to(arguments)
      expected  = {simple: :value}

      expect(stripped).to eq(expected)
    end

    context 'when redefining a property' do
      it 'raises a DuplicateProperty error by default' do
        runner = -> { properties_class.property(:simple) }
        expect(&runner).to raise_error(TestChamber::DuplicateProperty)
      end

      it 'allows overwriting previously defined properties' do
        runner = -> { properties_class.property(:simple, overwrite: true) }
        expect(&runner).not_to raise_error
      end

      it 'can be forced with property!' do
        runner = -> { properties_class.property!(:simple) }
        expect(&runner).not_to raise_error
      end
    end
  end
  context 'supports lazy defaults' do
    it 'does not execute the lambda until init' do
      called = false
      default = -> { called = true }

      properties_class.property(:lazy, default)
      expect(called).to eq(false)

      expect(properties.lazy).to eq(true)
      expect(called).to eq(true)
    end

    it 'will pass the properties object as an argument if arity is 1' do
      called = nil
      default = -> (p) { called = p.default_val }

      properties_class.property(:default_val, :default)
      properties_class.property(:lazy, default)
      expect(called).to eq(nil)

      expect(properties.lazy).to eq(:default)
      expect(called).to eq(:default)
    end

    it 'never calls the lambda if the arity is greater than 1' do
      called = false
      default = -> (p,s) { called = true }

      properties_class.property(:lazy, default)
      expect(called).to eq(false)

      expect(properties.lazy).to eq(default)
      expect(called).to eq(false)
    end
  end
  context 'when providing attributes' do
    before(:each) do
      properties_class.property(:simple)
      properties_class.property(:lazy, -> { :lazy })
    end

    it 'overwrites defined defaults' do
      properties = properties_class.new({
        simple: :value,
        lazy:   :value
      })

      expect(properties.simple).to eq(:value)
      expect(properties.lazy).to eq(:value)
    end

    it 'raises an error if an undefined property is given' do
      runner = -> { properties_class.new({nope: :fail}) }
      expect(&runner).to raise_error(TestChamber::PropertyNotSupported)
    end

    it 'allows ignoring default values' do
      properties = properties_class.new({simple: :value}, true)
      expect(properties.simple).to eq(:value)
      expect(properties.lazy).to be_nil
    end

    it 'provides a mechanism to get the default value of a property' do
      properties = properties_class.new({lazy: :value, simple: nil})

      expect(properties.fetch_with_default(:lazy)).to eq(:value)
      expect(properties.default_for(:lazy)).to eq(:lazy)

      expect(properties.fetch_with_default(:simple)).to eq(nil)
      expect(properties.default_for(:simple)).to eq(TestChamber::NoDefaultValue)
    end
  end
  context 'finding a properties object' do
    before(:each) do
      TestChamber.const_set(:UnitTest, Class.new)
      TestChamber.const_set(:UnitTestProperties, Class.new(described_class))
      TestChamber::UnitTestProperties.const_set(:Api, Class.new(TestChamber::UnitTestProperties))
    end
    after(:each) do
      TestChamber.send(:remove_const, :UnitTest)
      TestChamber.send(:remove_const, :UnitTestProperties)
    end

    it 'works based on the bare class name' do
      obj = TestChamber::UnitTest.new
      exp = TestChamber::UnitTestProperties::Api

      expect(described_class.class_for(obj)).to eq(exp)
    end

    it 'raises a PropertiesForActionNotDefined exception if no candidates are found' do
      obj = TestChamber::UnitTest.new
      TestChamber::UnitTestProperties.send(:remove_const, :Api)

      runner = -> { described_class.class_for(obj) }
      expect(&runner).to raise_error(TestChamber::PropertiesForActionNotDefined)
    end
  end
  context 'plays nicely with inheritance' do
    let(:subclass) { Class.new(properties_class) }
    let(:subsubclass) { Class.new(subclass) }

    it 'copies properties to the new subclass' do
      properties_class.property(:foo)
      expect(subclass).to be_supported(:foo)
    end

    it 'does not push new subclass properties back to the parent' do
      subclass.property(:foo)
      expect(subclass).to be_supported(:foo)
      expect(properties_class).not_to be_supported(:foo)
    end

    it 'pushes new parent properties down the subclass chain' do
      # Order here is important so we can test pushing properties *after* a class has already inherited
      subsubclass.property(:deepest)
      subclass.setting(:deep)
      properties_class.property(:shallow)

      expect(subsubclass).to be_supported(:deepest)
      expect(subsubclass).not_to be_setting(:deepest)
      expect(subsubclass).to be_setting(:deep)
      expect(subsubclass).to be_supported(:shallow)

      expect(subclass).not_to be_supported(:deepest)
      expect(subclass).not_to be_setting(:deepest)
      expect(subclass).to be_setting(:deep)
      expect(subclass).to be_supported(:shallow)

      expect(properties_class).not_to be_supported(:deepest)
      expect(properties_class).not_to be_setting(:deepest)
      expect(properties_class).not_to be_setting(:deep)
      expect(properties_class).to be_supported(:shallow)
    end
  end
end
