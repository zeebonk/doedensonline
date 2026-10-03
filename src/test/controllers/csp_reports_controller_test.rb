require 'test_helper'

class CspReportsControllerTest < ActionDispatch::IntegrationTest
  REPORT = {
    'csp-report' => {
      'document-uri' => 'http://www.example.com/news',
      'violated-directive' => 'script-src',
      'blocked-uri' => 'https://evil.example.com/x.js'
    }
  }.to_json

  test "pages send a report-only content security policy" do
    get '/sign_in', params: {}
    assert_response :success
    assert_nil response.headers['Content-Security-Policy']
    policy = response.headers['Content-Security-Policy-Report-Only']
    assert_includes policy, "script-src 'self' https://cdn.jsdelivr.net"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, 'report-uri /csp_reports'
  end

  test "create logs the report without requiring sign in" do
    log = StringIO.new
    old_logger = ActionController::Base.logger
    ActionController::Base.logger = Logger.new(log)
    begin
      post '/csp_reports', params: REPORT, headers: { 'CONTENT_TYPE' => 'application/csp-report' }
    ensure
      ActionController::Base.logger = old_logger
    end
    assert_response :no_content
    assert_includes log.string, "CSP violation: #{REPORT}"
  end

  test "create accepts reports with forgery protection enabled" do
    ActionController::Base.allow_forgery_protection = true
    post '/csp_reports', params: REPORT, headers: { 'CONTENT_TYPE' => 'application/csp-report' }
    assert_response :no_content
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
