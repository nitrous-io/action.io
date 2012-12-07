require 'spec_helper'

describe SignInToken do
  let(:user) { create :user }

  describe '.generate' do
    context 'when expiry_time argument is present' do
      it 'returns a sign_in_token for the given user and expiry_time' do
        expiry_time = Time.now + 1.minutes
        expect(SignInToken.generate(user, expiry_time)).to eq(
          Base64.urlsafe_encode64(
            DefaultMessageVerifier.verifier.generate [user.id, expiry_time.to_i]
          )
        )
      end
    end

    context 'when expiry_time argument is absent' do
      it 'returns a sign_in_token for the given user and current time + EXPIRY as the expiry time' do
        Timecop.freeze do
          expect(SignInToken.generate(user)).to eq(
            Base64.urlsafe_encode64(
              DefaultMessageVerifier.verifier.generate [user.id, (Time.now + SignInToken::EXPIRY).to_i]
            )
          )
        end
      end
    end
  end

  describe '.verify' do
    context 'when token is invalid' do
      let(:invalid_verifier) { ActiveSupport::MessageVerifier.new 'wrong_secret_token', serializer: JSON }
      let(:token) {
        Base64.urlsafe_encode64(
          invalid_verifier.generate [user.id, (Time.now + SignInToken::EXPIRY).to_i]
        )
      }

      it 'returns nil' do
        Timecop.freeze do
          expect(SignInToken.verify token).to be_nil
        end
      end
    end

    context 'when token is valid' do
      context 'when token is expired' do
        let(:token) { SignInToken.generate(user, Time.now) }

        it 'returns nil' do
          Timecop.freeze do
            expect(SignInToken.verify token).to be_nil
          end
        end
      end

      context 'when token is not expired' do
        context 'when token contains non existent user id' do
          let(:token) { SignInToken.generate(double id: 9001) }

          it 'returns nil' do
            Timecop.freeze do
              expect(SignInToken.verify token).to be_nil
            end
          end
        end

        context 'when token contains valid user id' do
          let(:token) { SignInToken.generate(user) }

          it 'returns user' do
            Timecop.freeze do
              expect(SignInToken.verify token).to eq user
            end
          end
        end
      end
    end
  end
end
