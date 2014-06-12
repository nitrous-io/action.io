require 'spec_helper'

describe BoxhostProviderTemplate do
  it { should allow_mass_assignment_of :provider }
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :config }
  it { should allow_mass_assignment_of :boxhost_plan_id }
  it { should allow_mass_assignment_of :region_id }

  it { should belong_to(:boxhost_plan) }
  it { should belong_to(:region) }

  it { should have_many(:boxhosts) }

  describe '#hostbuilder_class' do
    let(:boxhost_provider_template) { create :boxhost_provider_template, provider: 'digital_ocean' }

    it 'looks up the Hostbuilder class with its provider' do
      expect(Hostbuilder).to receive('by_name').with('digital_ocean')
      boxhost_provider_template.hostbuilder_class
    end
  end

  describe '#supported?' do
    let(:boxhost_provider_template) { create :boxhost_provider_template, provider: 'digital_ocean' }

    context 'when it has a Hostbuilder class' do
      before do
        expect(boxhost_provider_template).to receive(:hostbuilder_class).and_return(Hostbuilder::Base)
      end

      it 'returns true' do
        expect(boxhost_provider_template.supported?).to be_truthy
      end
    end

    context 'when it does not have a Hostbuilder class' do
      before do
        expect(boxhost_provider_template).to receive(:hostbuilder_class).and_return(nil)
      end

      it 'returns false' do
        expect(boxhost_provider_template.supported?).to be_falsey
      end
    end
  end
end
