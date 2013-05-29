require 'spec_helper'

describe UserSerializer do
  let!(:authentication) { create :authentication }
  let!(:user) { create :user, authentications: [authentication], available_invites: 10 }

  context 'when scope is the same user' do
    subject { user.serialize_as_json scope: user }

    it 'has users fields' do
      user.should_receive(:can?).with(:create, Box) { false }
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('admin'    ).should == user.admin
      hash.delete('username' ).should == user.username
      hash.delete('email'    ).should == user.email
      hash.delete('full_name').should == user.full_name
      hash.delete('available_invites').should eq(user.available_invites)
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.delete('sign_in_count').should eq(user.sign_in_count.as_json)
      hash.delete('authentications').should ==
        [JSON.parse(authentication.serialize_as_json)['authentication']]
      hash.delete('actions') .should eq({
        'create_box' => false
      })
      hash.delete('activated').should eq(user.activated?)
      hash.delete('sign_in_count').should eq(user.sign_in_count.as_json)
      hash.delete('hide_boxes_tour').should eq(user.hide_boxes_tour.as_json)
      hash.delete('hide_ide_tour').should eq(user.hide_ide_tour.as_json)
      hash.should be_empty
    end
  end

  context 'when scope is a different user' do
    let(:other_user) { create :user }

    subject { user.serialize_as_json scope: other_user }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end

  context 'when scope is not provided' do
    subject { user.serialize_as_json }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end
end
