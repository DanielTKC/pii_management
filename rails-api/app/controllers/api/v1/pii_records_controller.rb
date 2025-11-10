# frozen_string_literal: true

module Api
  module V1
    class PiiRecordsController < ApplicationController
      #  Auth off for now - to be integrated later
      skip_before_action :authenticate, raise: false
      before_action :set_pii_record, only: [:show, :update, :destroy]

      # GET /api/v1/pii_records
      def index
        @pii_records = PiiRecord.active
        render json: @pii_records.map { |record| pii_record_json(record) }
      end

      # GET /api/v1/pii_records/:id
      def show
        render json: pii_record_json(@pii_record)
      end

      # POST /api/v1/pii_records
      def create
        @pii_record = PiiRecord.new(pii_record_params)

        if @pii_record.save
          render json: pii_record_json(@pii_record), status: :created
        else
          render json: { errors: @pii_record.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/pii_records/:id
      def update
        if @pii_record.update(pii_record_update_params)
          render json: pii_record_json(@pii_record)
        else
          render json: { errors: @pii_record.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/pii_records/:id
      def destroy
        @pii_record.soft_delete
        head :no_content
      end

      private

      # Find active (non-deleted) PII record
      def set_pii_record
        @pii_record = PiiRecord.active.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Record not found' }, status: :not_found
      end

      # Strong parameters for create
      def pii_record_params
        params.require(:pii_record).permit(
          :first_name,
          :middle_name,
          :middle_name_override,
          :last_name,
          :ssn,
          :date_of_birth,
          :email,
          :phone,
          :street_address_1,
          :street_address_2,
          :city,
          :state,
          :zip_code
        )
      end

      # Strong parameters for update (exclude SSN - can't be changed)
      def pii_record_update_params
        params.require(:pii_record).permit(
          :first_name,
          :middle_name,
          :middle_name_override,
          :last_name,
          :date_of_birth,
          :email,
          :phone,
          :street_address_1,
          :street_address_2,
          :city,
          :state,
          :zip_code
        )
      end

      # Format PII record for JSON response
      # Never expose encrypted SSN - only show obfuscated version
      def pii_record_json(record)
        {
          id: record.id,
          first_name: record.first_name,
          middle_name: record.middle_name,
          last_name: record.last_name,
          ssn: record.display_ssn, # ***-**-XXXX format
          date_of_birth: record.date_of_birth,
          email: record.email,
          phone: record.phone,
          street_address_1: record.street_address_1,
          street_address_2: record.street_address_2,
          city: record.city,
          state: record.state,
          zip_code: record.zip_code,
          created_at: record.created_at,
          updated_at: record.updated_at
        }
      end
    end
  end
end
