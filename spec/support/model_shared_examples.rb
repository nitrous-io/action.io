shared_examples 'a model that has an encrypted attribute' do |klass, attribute|
  describe "#{attribute} encryption" do
    describe "##{attribute}=" do
      let(:model1)   { klass.new }
      let(:model2)   { klass.new }

      it "encrypts #{attribute} uniquely" do
        model1.send("encrypted_#{attribute}").should be_blank
        model1.send("encrypted_#{attribute}_iv").should be_blank
        model1.send("#{attribute}=", 'some top secret key')
        model1.send("encrypted_#{attribute}").should be_present
        model1.send("encrypted_#{attribute}_iv").should be_present
        model1.send(attribute).should_not == model1.send("encrypted_#{attribute}")

        model2.send("encrypted_#{attribute}").should be_blank
        model2.send("encrypted_#{attribute}_iv").should be_blank
        model2.send("#{attribute}=", 'some top secret key')
        model2.send("encrypted_#{attribute}").should be_present
        model2.send("encrypted_#{attribute}_iv").should be_present
        model2.send(attribute).should_not == model1.send("encrypted_#{attribute}")

        model1.send("encrypted_#{attribute}").should_not == model2.send("encrypted_#{attribute}")
        model1.send("encrypted_#{attribute}_iv").should_not == model2.send("encrypted_#{attribute}_iv")
      end
    end

    describe "##{attribute}" do
      let!(:model1) { build klass.to_s.tableize.singularize }

      before do
        model1.send("#{attribute}=", 'super proprietary and confidential key')
        model1.save!
      end

      it "decrypts encrypted #{attribute}" do
        model_instance = klass.find(model1.id)
        model_instance.send(attribute).should == 'super proprietary and confidential key'
      end
    end
  end


end
