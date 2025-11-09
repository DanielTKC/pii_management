# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SsnValidator do
  describe '.validate' do

    context 'with valid SSN formats' do
      it 'returns formatted SSN with dashes as valid' do
        result = SsnValidator.validate('234-56-7890')
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'returns ssn with no dashes as valid' do
        result = SsnValidator.validate('234567890')
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'returns  not valid for SSN with area number 001-665' do
        result = SsnValidator.validate('123-45-6789')
        expect(result[:valid]).to be false
      end

      it 'returns valid for area number 001' do
        result = SsnValidator.validate('001-12-3456')
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end


    context 'with invalid SSN formats' do
      it 'returns invalid for SSN with letters' do
        result = SsnValidator.validate('ABC-DE-FGHI')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN must contain only digits and dashes.')
      end

      it 'returns invalid for SSN that is too short' do
        result = SsnValidator.validate('12-34-567')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN must be 9 digits.')
      end

      it 'returns invalid for SSN that is too long' do
        result = SsnValidator.validate('123-45-67890')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN must be 9 digits.')
      end


      it 'returns invalid for SSN with incorrect dash placement' do
        result = SsnValidator.validate('1234-5-6789')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN format must be XXX-XX-XXXX or XXXXXXXXX.')
      end

      it 'returns invalid for empty string' do
        result = SsnValidator.validate('')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN cannot be null or empty.')
      end

      it 'returns invalid for nil' do
        result = SsnValidator.validate(nil)
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN cannot be null or empty.')
      end

      it 'returns invalid for SSN with special characters' do
        result = SsnValidator.validate('123@45#6789')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN must contain only digits and dashes.')
      end

      it 'returns invalid for SSN with spaces' do
        result = SsnValidator.validate('123 45 6789')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('SSN must contain only digits and dashes.')
      end
    end

    context 'with invalid area numbers' do
      it 'returns invalid for area number 000' do
        result = SsnValidator.validate('000-12-3456')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Area number cannot be 000.')
      end

      it 'returns invalid for area number 666' do
        result = SsnValidator.validate('666-12-3456')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Area number cannot be 666.')
      end
    end

    context 'with invalid group numbers' do
      it 'returns invalid for group number 00' do
        result = SsnValidator.validate('234-00-4567')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Group number cannot be 00.')
      end
    end

    context 'with invalid serial numbers' do
      it 'returns invalid for serial number 0000' do
        result = SsnValidator.validate('234-56-0000')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Serial number cannot be 0000.')
      end
    end

    context 'with known invalid SSNs' do
      it 'returns invalid for 078-05-1120 (Woolworth wallet card)' do
        result = SsnValidator.validate('078-05-1120')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('This SSN is a known invalid number.')
      end

      it 'returns invalid for 219-09-9999' do
        result = SsnValidator.validate('219-09-9999')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('This SSN is a known invalid number.')
      end

      it 'returns invalid for 123-45-6789 (common placeholder)' do
        result = SsnValidator.validate('123-45-6789')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('This SSN is a known invalid number.')
      end
    end

    context 'with multiple validation errors' do

      it 'returns all applicable errors for 000-00-0000' do

        result = SsnValidator.validate('000-00-0000')
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Area number cannot be 000.')
        expect(result[:errors]).to include('Group number cannot be 00.')
        expect(result[:errors]).to include('Serial number cannot be 0000.')
        expect(result[:errors].length).to eq(3)

      end
    end
  end
end

