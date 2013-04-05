require 'spec_helper'

describe AuthToken do
  let(:user) { create :user }

  describe '.generate' do
    context 'when expiry_time argument is present' do
      it 'returns a sign_in_token for the given user and expiry_time' do
        expiry_time = Time.now + 1.minutes
        expect(AuthToken.generate(user, 'sign_in', expiry_time)).to eq(
          Base64.urlsafe_encode64(
            DefaultMessageVerifier.verifier.generate [user.id, 'sign_in', expiry_time.to_i]
          )
        )
      end
    end

    context 'when expiry_time argument is absent' do
      it 'returns a sign_in_token for the given user and current time + EXPIRY as the expiry time' do
        Timecop.freeze do
          expect(AuthToken.generate(user, 'sign_in')).to eq(
            Base64.urlsafe_encode64(
              DefaultMessageVerifier.verifier.generate [user.id, 'sign_in', (Time.now + AuthToken::EXPIRY).to_i]
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
          invalid_verifier.generate [user.id, 'sign_in', (Time.now + AuthToken::EXPIRY).to_i]
        )
      }

      it 'returns nil' do
        Timecop.freeze do
          expect(AuthToken.verify token, 'sign_in').to be_nil
        end
      end
    end

    context 'when token is valid' do
      context 'when token is expired' do
        let(:token) { AuthToken.generate(user, 'sign_in', Time.now) }

        it 'returns nil' do
          Timecop.freeze do
            expect(AuthToken.verify token, 'sign_in').to be_nil
          end
        end
      end

      context 'when token is not expired' do
        context 'when token contains non existent user id' do
          let(:token) { AuthToken.generate(double(id: 9001), 'sign_in') }

          it 'returns nil' do
            Timecop.freeze do
              expect(AuthToken.verify token, 'sign_in').to be_nil
            end
          end
        end

        context 'when the token contains a valid user id' do
          let(:token) { AuthToken.generate user, 'sign_in' }

          it 'returns user' do
            Timecop.freeze do
              expect(AuthToken.verify token, 'sign_in').to eq user
            end
          end
        end

        context 'when the name embedded in the token does not match the given name' do
          let(:token) { AuthToken.generate(user, 'rainbow') }

          it 'returns user' do
            Timecop.freeze do
              expect(AuthToken.verify token, 'sign_in').to be_nil
            end
          end
        end
      end
    end
  end
end
