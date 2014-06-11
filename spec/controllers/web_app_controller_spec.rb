require 'spec_helper'

describe WebAppController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:another_user) { create :user }
    let!(:region1) { create :region, enabled: true }
    let!(:region2) { create :region, enabled: true }
    let!(:region3) { create :region }
    let!(:box_template1) { create :box_template }
    let!(:box_template2) { create :box_template }
    let!(:box1) { create :box, box_template: box_template1, owner: user, users: [user], region: region1 }
    let!(:box2) { create :box, box_template: box_template1, owner: user, users: [user, another_user], region: region1 }
    let!(:box3) { create :box, box_template: box_template2, owner: another_user, users: [another_user], region: region1 }
    let!(:box4) { create :box, box_template: box_template1, owner: user, users: [user], region: region1 }
    let!(:box5) { create :box, box_template: box_template1, owner: user, users: [user], region: region1 }
    let!(:snapshot1) { create :snapshot, box: box1, user: user }
    let!(:snapshot2) { create :snapshot, box: box2, user: user }
    let!(:snapshot3) { create :snapshot, box: box2, user: user, state: 'deleted' }
    let!(:snapshot4) { create :snapshot, box: box3, user: another_user }
    let!(:repo1) { create :repository, box: box1 }
    let!(:repo2) { create :repository, box: box2 }
    let!(:repo3) { create :repository, box: box3 }
    let!(:repo4) { create :repository, box: box4 }
    let!(:repo5) { create :repository, box: box5 }
    let!(:key1) { create :public_key, user: user }
    let!(:key2) { create :public_key, user: another_user }
    let!(:key3) { create :public_key, user: user }
    let!(:global_plan_group) { create :plan_group, name: PlanGroup::DEFAULT_NAME }

    let!(:plan1) { create :plan }
    let!(:plan2) { create :plan }

    let!(:special_plan_group) { create :plan_group, name: 'special' }

    let!(:plan3) { create :plan }
    let!(:plan4) { create :plan }

    let!(:team_plans_group) { create :plan_group, name: PlanGroup::TEAM_NAME }
    let!(:plan5)            { create :plan }
    let!(:plan6)            { create :plan }

    let!(:boxhost_plan1) { create :boxhost_plan }
    let!(:boxhost_plan2) { create :boxhost_plan }

    let!(:boxhost1) { create :dedicated_boxhost, owner: user, boxhost_plan: boxhost_plan1 }
    let!(:boxhost2) { create :dedicated_boxhost, owner: user, boxhost_plan: boxhost_plan2 }

    before do
      KeyValue.create key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      KeyValue.create key: N2oAllocation::N2O_250MB_STORAGE, value: 10
      KeyValue.create key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5

      KeyValue.create key: Box::N2O_MIN_MEMORY_MB,  value: 384
      KeyValue.create key: Box::N2O_MIN_STORAGE_MB, value: 1000

      KeyValue.create key: Box::N2O_MAX_MEMORY_MB,  value: 2048
      KeyValue.create key: Box::N2O_MAX_STORAGE_MB, value: 10000

      global_plan_group.plans << plan1
      global_plan_group.plans << plan2

      special_plan_group.plans << plan3
      special_plan_group.plans << plan4

      team_plans_group.plans << plan5
      team_plans_group.plans << plan6
    end

    def do_request
      get :index
    end

    context 'when logged in' do
      before do
        sign_in user
        Timecop.freeze do
          box4.update_attribute :terminated_at, 1.day.ago + 1.second
          box5.update_attribute :terminated_at, 1.day.ago
        end
      end

      context "when user doesn't belong to a plan group" do
        before { do_request }

        it { should render_template 'index' }
        it { should respond_with :success }

        it 'sets ivars for the view' do
          expect(assigns(:boxes        )).to match_array([box1, box2])
          expect(assigns(:snapshots    )).to match_array([snapshot1, snapshot2])
          expect(assigns(:repositories )).to match_array([repo1, repo2])
          expect(assigns(:public_keys  )).to match_array([key1, key3])
          expect(assigns(:regions      )).to match_array([region1, region2])
          expect(assigns(:box_templates)).to match_array([box_template1, box_template2])
          expect(assigns(:personal_plan_ids)).to match_array([plan1.id, plan2.id])
          expect(assigns(:team_plan_ids)).to match_array([])
          expect(assigns(:plans)).to  match_array([plan1, plan2])
          expect(assigns(:n2o_128mb_memory)).to  eq 40
          expect(assigns(:n2o_250mb_storage)).to eq 10
          expect(assigns :bonus).to eq user.bonus
          expect(assigns(:bonus_info).symbolize_keys).to eq Bonus.bonus_info
          expect(assigns(:coupon_code)).to be_nil
          expect(assigns(:min_memory_in_mb)).to eql 384
          expect(assigns(:min_storage_in_mb)).to eql 1000
          expect(assigns(:max_memory_in_mb)).to eql 2048
          expect(assigns(:max_storage_in_mb)).to eql 10000
        end
      end

      context 'when coupon_code cookie is present in the request' do
        before { request.cookies['coupon_code'] = 'much-savings' }

        it 'should set the coupon_code ivar to its value' do
          do_request
          expect(assigns(:coupon_code)).to eq('much-savings')
        end

        it 'should delete the cookie' do
          do_request
          expect(response.cookies['coupon_code']).to be_nil
        end
      end

      context 'when user belongs to the non-global plan group' do
        before do
          user.plan_group = special_plan_group; user.save
        end

        it 'should show plans that belong to the special plan group' do
          do_request
          expect(assigns(:personal_plan_ids)).to match_array([plan3.id, plan4.id])
          expect(assigns(:team_plan_ids)).to match_array([])
          expect(assigns(:plans)).to match_array([plan3, plan4])
        end
      end

      context 'when user has team plans enabled' do
        before do
          user.update_attribute(:team_plans_enabled, true)
        end

        it 'should show plans that belong to the team plans group' do
          do_request
          expect(assigns(:personal_plan_ids)).to match_array([plan1.id, plan2.id])
          expect(assigns(:team_plan_ids)).to match_array([plan5.id, plan6.id])
          expect(assigns(:plans)).to match_array([plan1, plan2, plan5, plan6])
        end
      end

      context 'when user belongs to a defunct plan' do
        let!(:defunct_plan) { create :plan }
        let!(:subscription) { create :subscription, state: 'active', user: user, plan: defunct_plan }

        it 'includes info for defunct plan' do
          do_request
          expect(assigns(:personal_plan_ids)).to match_array([plan1.id, plan2.id])
          expect(assigns(:team_plan_ids)).to match_array([])
          expect(assigns(:plans)).to match_array([plan1, plan2, defunct_plan])
        end
      end

      context 'when user is allowed to view dedicated plans' do
        before do
          user.update_attribute(:dedicated_allowed, true)
        end

        it 'assigns all boxhost plans to @boxhost_plans' do
          do_request
          expect(assigns(:boxhost_plans)).to match_array [boxhost_plan1, boxhost_plan2]
        end

        it 'assigns owned boxes to @boxhosts' do
          do_request
          expect(assigns(:boxhosts)).to match_array [boxhost1, boxhost2]
        end
      end

      context 'when user is not allowed to view dedicated plans' do
        it 'does not assign boxhost-related ivars' do
          do_request
          expect(assigns(:boxhost_plans)).to be_nil
          expect(assigns(:boxhosts)).to be_nil
        end
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
