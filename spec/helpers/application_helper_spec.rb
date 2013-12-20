require 'spec_helper'

describe ApplicationHelper do
  describe '#full_controller_action_name' do
    let(:action_name) { 'index' }
    let(:controller_path) { 'home' }

    context 'when controller name does not contain namespace' do
      it 'returns "<controller name> <action name>"' do
        expect(full_controller_action_name).to eq('home index')
      end
    end

    context 'when controller name contains namespace' do
      let(:controller_path) { 'developer/apps' }

      it 'returns "<controller name with underscore as namespace separator> <action name>"' do
        expect(full_controller_action_name).to eq('developer_apps index')
      end
    end

    context 'when fullscreen=1 in the params' do
      let(:params) { { fullscreen: '1' } }

      it 'returns "<controller name> <action name> fullscreen"' do
        expect(full_controller_action_name).to eq('home index fullscreen')
      end
    end
  end

  describe '#nav_li' do
    let(:doc) { Nokogiri.parse(nav_li('Subscriptions', '/subscriptions')) }
    let(:request) { double('request') }

    before { request.stub(:fullpath) }

    it 'renders list item containing a link to the path' do
      expect(doc.element_children.count).to eq(1)
      expect(doc.first_element_child.name).to eq('li')
      link = doc.css('li a').first
      expect(link.content).to eq('Subscriptions')
      expect(link['href']).to eq('/subscriptions')
    end

    context 'when the given path is the current path' do
      before { request.stub(:fullpath) { '/subscriptions' } }

      it 'adds the classname "active"' do
        expect(doc.first_element_child['class']).to eq('active')
      end
    end
  end
end

