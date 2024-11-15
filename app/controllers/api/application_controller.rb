module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_api_key

    private

    def authenticate_api_key
      api_key = request.headers['API-KEY']

      unless ApiClient.exists?(api_key: api_key)
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
