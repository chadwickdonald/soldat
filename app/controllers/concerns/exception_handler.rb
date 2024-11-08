module ExceptionHandler
  extend ActiveSupport::Concern

  class RecordNotFound < StandardError; end
  class InvalidParameters < StandardError; end

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request

    rescue_from ExceptionHandler::RecordNotFound, with: :not_found
    rescue_from ExceptionHandler::InvalidParameters, with: :unprocessable_entity
  end

  private

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
