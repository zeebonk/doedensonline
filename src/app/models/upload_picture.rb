require 'mini_magick'

class UploadPicture
  ALLOWED_EXTENSIONS = %w[.jpg .jpeg .png .gif].freeze
  MAX_SIZE_BYTES = 10 * 1024 * 1024

  attr_accessor :filename, :source_image, :error

  class InvalidUpload < StandardError; end

  # The initialisation method
  def initialize(upload)
    validate!(upload)

    # Load the image and create a new filename
    source = upload.respond_to?(:tempfile) ? upload.tempfile : upload
    source.binmode if source.respond_to?(:binmode)
    @source_image = MiniMagick::Image.read(source)
    @filename = "#{Time.now.strftime('%d%m%Y%H%M%S')}#{Time.now.usec}.jpg"
  end

  # This method creates a medium copy of the source image
  def create_small_image
    picture_in_canvas = draw_picture_in_canvas 90, 90
    picture_in_canvas.write "public/images/small/#{@filename}"
  end

  # This method creates a medium copy of the source image
  def create_medium_image
    picture_in_canvas = draw_picture_in_canvas 208, 156
    picture_in_canvas.write "public/images/medium/#{@filename}"
  end

  # This method creates a large copy of the source image
  def create_large_image
    @source_image.resize "1024x768"
    resized_image = @source_image
    resized_image.format "JPEG"
    resized_image.quality "80"
    resized_image.write "public/images/large/#{@filename}"
  end

  private

  def validate!(upload)
    raise InvalidUpload, "no upload" if upload.nil?

    name = upload.respond_to?(:original_filename) ? upload.original_filename.to_s : ''
    extension = File.extname(name).downcase
    raise InvalidUpload, "unsupported extension: #{extension.inspect}" unless ALLOWED_EXTENSIONS.include?(extension)

    size =
      if upload.respond_to?(:size)
        upload.size
      elsif upload.respond_to?(:tempfile)
        upload.tempfile.size
      else
        File.size(upload.path)
      end
    raise InvalidUpload, "file too large: #{size} bytes" if size && size > MAX_SIZE_BYTES
  end

  def draw_picture_in_canvas(width, height)
    # Create a new image with the size of the box and a white background
    canvas = MiniMagick::Image.open "#{Rails.root}/public/images/temp.bmp"
    canvas.resize "#{width}x#{height}!"

    # Create thumb to fit the dimensions
    @source_image.resize "#{width}x#{height}"
    small_image = @source_image

    # Calculate position
    top  = small_image[:height] < height ? (height - small_image[:height]) / 2 : 0
    left = small_image[:width] < width ? (width - small_image[:width]) / 2 : 0

    # Draw the thumb on the image and save it
    canvas.draw "image Over #{left},#{top} 0,0 '#{small_image.path}'"

    canvas
  end
end
