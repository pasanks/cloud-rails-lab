class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # A missing or unreachable resource (database, Redis/Valkey, bucket) shows a
  # friendly "unavailable" page instead of a 500. The break-it routes (/boom etc.)
  # raise other errors, so they still fail for real.
  # Error classes are given as strings so their gems are only loaded when needed.
  rescue_from ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid,
    "RedisClient::Error", "Aws::Errors::ServiceError", with: :resource_unavailable

  private

  def resource_unavailable(exception)
    logger.error "[resource unavailable] #{exception.class}: #{exception.message}"
    render "shared/unavailable", status: :service_unavailable, locals: { exception: exception }
  end
end
