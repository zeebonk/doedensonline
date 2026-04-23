require 'test_helper'

class UploadPictureTest < ActiveSupport::TestCase
  FIXTURE_PATH = File.expand_path('../../fixtures/files/sample.jpg', __FILE__)

  def teardown
    return unless @uploader
    %w[large medium small].each do |size|
      path = Rails.root.join('public', 'images', size, @uploader.filename)
      File.delete(path) if File.exist?(path)
    end
  end

  test "accepts a Rails UploadedFile whose tempfile is not in binary mode" do
    # Reproduces the production bug: ActionDispatch::Http::UploadedFile wraps a
    # Tempfile that inherits Encoding.default_external (UTF-8). Without forcing
    # binmode, MiniMagick's IO.copy_stream raises on the first non-UTF-8 byte
    # in a JPEG (e.g. \xFF), which the controller swallows as "unsupported image".
    tempfile = Tempfile.new('upload')
    FileUtils.copy_file(FIXTURE_PATH, tempfile.path)
    refute tempfile.binmode?, 'sanity check: tempfile should not start in binmode'

    upload = ActionDispatch::Http::UploadedFile.new(
      :tempfile => tempfile,
      :filename => 'sample.jpg',
      :type     => 'image/jpeg'
    )

    @uploader = UploadPicture.new(upload)
    @uploader.create_large_image
    @uploader.create_medium_image
    @uploader.create_small_image

    %w[large medium small].each do |size|
      path = Rails.root.join('public', 'images', size, @uploader.filename)
      assert File.exist?(path), "expected #{size} variant to be written to #{path}"
    end
  end
end
