require 'spec_helper'

describe AppUpdate do
  it { should allow_mass_assignment_of :version }
  it { should allow_mass_assignment_of :title }
  it { should allow_mass_assignment_of :release_notes }
  it { should allow_mass_assignment_of :url }
  it { should allow_mass_assignment_of :file_size }
  it { should allow_mass_assignment_of :published }
  it { should_not allow_mass_assignment_of :published_at }

  describe 'validations' do
    let!(:app_update) { create :app_update }

    it { should validate_presence_of :version }
    it { should validate_presence_of :title }
    it { should validate_presence_of :release_notes }
    it { should validate_presence_of :url }
    it { should validate_presence_of :file_size }

    it 'is not valid when file_size is 0 and published_at is not nil' do
      app_update.published_at = nil
      app_update.file_size = 0
      expect {
        app_update.published_at = Time.zone.now
      }.to change { app_update.valid? }.from(true).to(false)
    end
  end

  describe '.published' do
    let!(:app_update1) { create :app_update, published_at: 2.days.ago }
    let!(:app_update2) { create :app_update, published_at: nil }
    let!(:app_update3) { create :app_update, published_at: 3.day.ago }
    let!(:app_update4) { create :app_update, published_at: 1.day.ago }

    it 'returns objects that are published (published_at is not nil), sorted by published_at desc' do
      expect(described_class.published).to eq([app_update4, app_update1, app_update3])
    end
  end

  describe ".latest_url" do
    let!(:app_update1) { create :app_update, platform: 'mac', published_at: 2.days.ago }
    let!(:app_update2) { create :app_update, platform: 'mac', published_at: nil }
    let!(:app_update3) { create :app_update, platform: 'mac', published_at: 3.days.ago }
    let!(:app_update4) { create :app_update, platform: 'windows', published_at: 2.days.ago }
    let!(:app_update5) { create :app_update, platform: 'windows', published_at: 1.day.ago }

    it 'returns the url of the most recently published app update for the given platform' do
      expect(described_class.latest_url('mac')).to eq(app_update1.url)
      expect(described_class.latest_url('windows')).to eq(app_update5.url)
    end
  end

  describe '#published=' do
    let!(:app_update) { create :app_update }

    it 'sets published_at to be current datetime when true' do
      Timecop.freeze do
        app_update.published_at = nil
        app_update.published = true
        expect(app_update.published).to be_truthy
        expect(app_update.published_at.to_i).to eq(Time.zone.now.to_i)
      end
    end

    it 'sets published_at to be current datetime when 1' do
      Timecop.freeze do
        app_update.published_at = nil
        app_update.published = '1'
        expect(app_update.published).to be_truthy
        expect(app_update.published_at.to_i).to eq(Time.zone.now.to_i)
      end
    end

    context 'when published_at is already set' do
      it 'does not update the value' do
        app_update.published_at = 1.day.ago
        app_update.published = true
        expect(app_update.published).to be_truthy
        expect(app_update.published_at.to_i).to eq(1.day.ago.to_i)
      end
    end

    it 'sets published_at to be nil when false' do
      app_update.published_at = Time.zone.now
      app_update.published = false
      expect(app_update.published).to be_falsey
      expect(app_update.published_at).to be_nil
    end

    it 'sets published_at to be nil when 0' do
      app_update.published_at = Time.zone.now
      app_update.published = '0'
      expect(app_update.published).to be_falsey
      expect(app_update.published_at).to be_nil
    end
  end

  describe '#release_notes_in_html' do
    let!(:app_update) { create :app_update, release_notes: '_italic_ **bold**' }

    it 'renders release_notes markdown markup as html' do
      expect(app_update.release_notes_in_html).to eq('<p><em>italic</em> <strong>bold</strong></p>')
    end
  end
end
