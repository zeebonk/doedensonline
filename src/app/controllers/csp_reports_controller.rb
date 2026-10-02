# Receives Content-Security-Policy violation reports from browsers and logs
# them. Inherits from ActionController::Base so it skips sign-in, and browsers
# don't send a CSRF token with reports.
class CspReportsController < ActionController::Base
  MAX_REPORT_SIZE = 16.kilobytes

  skip_forgery_protection

  def create
    report = request.body.read(MAX_REPORT_SIZE)
    logger.warn("CSP violation: #{report}") if report.present?
    head :no_content
  end
end
