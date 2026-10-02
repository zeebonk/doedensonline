# Report-only for now: violations are logged by CspReportsController. Switch
# content_security_policy_report_only to false once the reports are clean.
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  # TinyMCE (plus its plugins, language pack and content CSS) and ColorBox are
  # loaded from jsDelivr. TinyMCE and ColorBox set inline styles at runtime.
  policy.script_src  :self, 'https://cdn.jsdelivr.net'
  policy.style_src   :self, 'https://cdn.jsdelivr.net', :unsafe_inline
  # Old news items may embed external images.
  policy.img_src     :self, :data, :blob, :https
  policy.font_src    :self, 'https://cdn.jsdelivr.net', :data
  policy.connect_src :self, 'https://cdn.jsdelivr.net'
  policy.object_src  :none
  policy.base_uri    :self
  policy.form_action :self
  policy.frame_ancestors :none
  policy.report_uri '/csp_reports'
end

Rails.application.config.content_security_policy_report_only = true
