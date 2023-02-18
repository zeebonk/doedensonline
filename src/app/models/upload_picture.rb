
require 'mini_magick'

class UploadPicture

  attr_accessor :filename, :source_image, :error
 
  
  # The initialisation method
  def initialize upload
    
    # Load the image and create a new filename
    @source_image = MiniMagick::Image.read(upload)
    @filename      = "#{Time.now.strftime("%d%m%Y%H%M%S")}#{Time.now.usec}.jpg"
    
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
		#picture_in_canvas = draw_picture_in_canvas 1024, 768
  	#picture_in_canvas.write "public/images/large/#{@filename}"
  end
  
  
private  

  
  def draw_picture_in_canvas width, height
    
  	# Create a new image with the size of the box and a white background
    canvas = MiniMagick::Image.from_file  "#{RAILS_ROOT}/public/images/temp.jpg"
    canvas.resize "#{width}x#{height}!"
  	
    # Create thumb to fit the dimensions
		@source_image.thumbnail "#{width}x#{height}"
    small_image = @source_image
    
    # Calculate position
    top  = (small_image[:height] < height) ? (height - small_image[:height]) / 2 : 0
    left = (small_image[:width ] < width ) ? (width  - small_image[:width ]) / 2 : 0
    
    # Draw the thumb on the image and save it
    canvas.draw "image Over #{left},#{top} 0,0 '#{small_image.path}'"
    
    return canvas
  	
  end
  
  
end