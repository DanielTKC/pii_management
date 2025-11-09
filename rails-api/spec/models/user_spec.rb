require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    describe 'email' do
      it 'is invalid without an email' do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is invalid with a duplicate email' do
        create(:user, email: 'test@example.com')
        duplicate_user = build(:user, email: 'test@example.com')
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include('has already been taken')
      end

      it 'is invalid with an improperly formatted email' do
        invalid_emails = [
          'invalid',
          'invalid@',
          '@example.com',
          'invalid email@example.com',
          'invalid@.com'
        ]

        invalid_emails.each do |invalid_email|
          user = build(:user, email: invalid_email)
          expect(user).not_to be_valid, "#{invalid_email} should be invalid"
          expect(user.errors[:email]).to include('is invalid')
        end
      end

      it 'saves email as lowercase' do
        user = create(:user, email: 'USER@EXAMPLE.COM')
        expect(user.reload.email).to eq('user@example.com')
      end

      it 'is valid with properly formatted emails' do
        valid_emails = [
          'user@example.com',
          'test.user@example.com',
          'user+tag@example.co.uk',
          'user_name@example-domain.com'
        ]

        valid_emails.each do |valid_email|
          user = build(:user, email: valid_email)
          expect(user).to be_valid, "#{valid_email} should be valid"
        end
      end
    end

    describe 'password' do
      it 'is invalid without a password' do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'is invalid with a password shorter than 6 characters' do
        user = build(:user, password: 'short', password_confirmation: 'short')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'is valid with a password of 6 characters' do
        user = build(:user, password: '123456', password_confirmation: '123456')
        expect(user).to be_valid
      end

      it 'is valid with a long password' do
        user = build(:user, password: 'a' * 72, password_confirmation: 'a' * 72)
        expect(user).to be_valid
      end
    end
  end

  describe 'authentication' do
    let(:user) { create(:user, email: 'auth@example.com', password: 'correctpassword') }

    it 'authenticates with correct password' do
      expect(user.authenticate('correctpassword')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      expect(user.authenticate('wrongpassword')).to be_falsey
    end

    it 'does not authenticate with nil password' do
      expect(user.authenticate(nil)).to be_falsey
    end

    it 'does not authenticate with empty password' do
      expect(user.authenticate('')).to be_falsey
    end
  end
end
