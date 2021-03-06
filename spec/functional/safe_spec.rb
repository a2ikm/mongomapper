require 'spec_helper'

describe "Safe" do
  context "A Document" do
    it "should default safe to off" do
      Doc().should_not be_safe
    end

    it "should allow turning safe on" do
      Doc() { safe }.should be_safe
    end

    context "inherited with safe setting on" do
      it "should set subclass safe setting on" do
        inherited = Class.new(Doc() { safe })
        inherited.should be_safe
        inherited.safe_options.should == true
      end

      it "should set subclass safe setting to same options hash as superclass" do
        inherited = Class.new(Doc() { safe(:j => true) })
        inherited.should be_safe
        inherited.safe_options.should == {:j => true}
      end
    end

    context "inherited with safe setting off" do
      it "should leave subclass safe setting off" do
        inherited = Class.new(Doc())
        inherited.should_not be_safe
      end
    end
  end

  context "An unsafe document" do
    before do
      @klass = Doc do
        safe(:w => 0)
      end
    end
    after { drop_indexes(@klass) }

    it "should not raise an error on duplicate IDs" do
      k = @klass.create
      lambda { j = @klass.create(:_id => k.id) }.should_not raise_error
    end
  end

  context "A safe document" do
    before do
      @klass = Doc() do
        safe
      end
    end
    after { drop_indexes(@klass) }

    context "#save" do
      before do
        @klass.ensure_index :email, :unique => true
      end

      it "should raise an error on duplicate IDs" do
        k = @klass.create
        lambda { j = @klass.create(:_id => k.id) }.should raise_error(Mongo::Error::OperationFailure)
      end

      context "using safe setting from class" do
        it "should pass :w => 1 option to the collection" do
          @klass.collection.write_concern.options.should == { w: 1 }
        end

        it "should work fine when all is well" do
          lambda {
            @klass.new(:email => 'john@doe.com').save
          }.should_not raise_error
        end

        it "should raise error when operation fails" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save
            end
          }.should raise_error(Mongo::Error::OperationFailure)
        end
      end

      context "overriding safe setting" do
        it "should raise error if safe is true" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => true)
            end
          }.should raise_error(Mongo::Error::OperationFailure)
        end

        it "should not raise error if safe is false" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => false)
            end
          }.should_not raise_error
        end
      end
    end
  end

  context "a safe document with options hash" do
    before do
      @klass = Doc() do
        safe(:j => true)
      end
    end
    after { drop_indexes(@klass) }

    context "#save" do
      before do
        @klass.ensure_index :email, :unique => true
      end

      context "using safe setting from class" do
        it "should pass :safe => options_hash to the collection" do
          @klass.collection.write_concern.options.should == { j: true }
        end

        it "should work fine when all is well" do
          lambda {
            @klass.new(:email => 'john@doe.com').save
          }.should_not raise_error
        end

        it "should raise error when operation fails" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save
            end
          }.should raise_error(Mongo::Error::OperationFailure)
        end
      end

      context "overriding safe setting" do
        it "should raise error if safe is true" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => true)
            end
          }.should raise_error(Mongo::Error::OperationFailure)
        end

        it "should not raise error if safe is false" do
          lambda {
            2.times do
              @klass.new(:email => 'john@doe.com').save(:safe => false)
            end
          }.should_not raise_error
        end
      end
    end
  end
end
