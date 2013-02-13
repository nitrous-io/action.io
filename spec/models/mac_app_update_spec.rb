require 'spec_helper'

describe MacAppUpdate do
  it { should allow_mass_assignment_of :version }
  it { should allow_mass_assignment_of :title }
  it { should allow_mass_assignment_of :release_notes }
  it { should allow_mass_assignment_of :url }
  it { should allow_mass_assignment_of :file_size }
  it { should allow_mass_assignment_of :published }
  it { should_not allow_mass_assignment_of :published_at }

  describe 'validations' do
    let!(:mac_app_update) { create :mac_app_update }

    it { should validate_presence_of :version }
    it { should validate_presence_of :title }
    it { should validate_presence_of :release_notes }
    it { should validate_presence_of :url }
    it { should validate_presence_of :file_size }

    it 'is not valid when file_size is 0 and published_at is not nil' do
      mac_app_update.published_at = nil
      mac_app_update.file_size = 0
      expect {
        mac_app_update.published_at = Time.zone.now
      }.to change { mac_app_update.valid? }.from(true).to(false)
    end
  end

  describe '.published' do
    let!(:mac_app_update1) { create :mac_app_update, published_at: 2.days.ago }
    let!(:mac_app_update2) { create :mac_app_update, published_at: nil }
    let!(:mac_app_update3) { create :mac_app_update, published_at: 3.day.ago }
    let!(:mac_app_update4) { create :mac_app_update, published_at: 1.day.ago }

    it 'returns objects that are published (published_at is not nil), sorted by published_at desc' do
      expect(described_class.published).to eq([mac_app_update4, mac_app_update1, mac_app_update3])
    end
  end

  describe '#published/#published=' do
    let!(:mac_app_update) { create :mac_app_update }

    it 'sets published_at to be current datetime when true' do
      Timecop.freeze do
        mac_app_update.published = true
        expect(mac_app_update.published).to be_true
        expect(mac_app_update.published_at.to_i).to eq(Time.zone.now.to_i)
      end
    end

    it 'sets published_at to be current datetime when 1' do
      Timecop.freeze do
        mac_app_update.published = '1'
        expect(mac_app_update.published).to be_true
        expect(mac_app_update.published_at.to_i).to eq(Time.zone.now.to_i)
      end
    end

    it 'sets published_at to be nil when false' do
      mac_app_update.published = false
      expect(mac_app_update.published).to be_false
      expect(mac_app_update.published_at).to be_nil
    end

    it 'sets published_at to be nil when 0' do
      mac_app_update.published = '0'
      expect(mac_app_update.published).to be_false
      expect(mac_app_update.published_at).to be_nil
    end
  end

  describe '#release_notes_in_html' do
    let!(:mac_app_update) { create :mac_app_update, release_notes: '_italic_ **bold**' }

    it 'renders release_notes markdown markup as html' do
      expect(mac_app_update.release_notes_in_html).to eq('<p><em>italic</em> <strong>bold</strong></p>')
    end
  end
end
