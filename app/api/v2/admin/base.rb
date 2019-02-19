# frozen_string_literal: true

require_dependency 'barong/middleware/jwt_authenticator'

module API::V2
  module Admin
    class Base < Grape::API
      use Barong::Middleware::JWTAuthenticator, \
        pubkey: Rails.configuration.x.keystore.public_key

      cascade false

      format         :json
      content_type   :json, 'application/json'
      default_format :json

      helpers API::V2::Resource::Utils
      helpers API::V2::Admin::Utils

      do_not_route_options!

      before do
        error!({ errors: ['admin.access.denied'] }, 401) unless current_user.role.admin?
      end

      rescue_from(ActiveRecord::RecordNotFound) do |_e|
        error!({ errors: ['record.not_found'] }, 404)
      end

      rescue_from(Grape::Exceptions::ValidationErrors) do |error|
        error!(error.message, 400)
      end

      rescue_from Peatio::Auth::Error do |e|
        if Rails.env.production?
          error!('Permission Denied', 401)
        else
          Rails.logger.error "#{e.class}: #{e.message}"
          error!({ error: { code: e.code, message: e.message } }, 401)
        end
      end

      # Known Vault Error from TOTPService.with_human_error
      rescue_from(TOTPService::Error) do |error|
        error!(error.message, 422)
      end

      rescue_from(:all) do |error|
        Rails.logger.error "#{error.class}: #{error.message}"
        error!('Something went wrong', 500)
      end

      mount Admin::Users
    end
  end
end
