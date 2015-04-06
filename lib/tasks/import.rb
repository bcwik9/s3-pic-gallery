namespace :pictures do
  require 'fileutils'
  
  S3_BUCKET_NAME = ENV['S3_BUCKET_NAME'] || raise('please set environment var S3_BUCKET_NAME')
  
  desc 'Download pictures from a S3 bucket to assets'
  task :import => :environment do
    # important directories
    asset_dir = File.join 'app', 'assets', 'images'
    thumb_dir = File.join asset_dir, 'thumbnails'
    mkdir_p thumb_dir
    compress_dir = File.join asset_dir, 'compressed'
    mkdir_p compress_dir
    
    # iterate through objects in the bucket and create thumbnails and compress images
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket S3_BUCKET_NAME
    objects = bucket.objects
    num_objects = objects.to_a.size
    puts "Processing #{num_objects} objects from #{S3_BUCKET_NAME}"
    objects.each_with_index do |o,i|
      # get image filename
      img_name = o.object.key

      puts "Processing #{img_name} #{i}/#{num_objects} (#{i.to_f/num_objects*100})%"
      
      next if File.extname(img_name).empty? # skip folder objects (non images)
      # create RMagick image
      img = Magick::Image.from_blob(o.object.get.data.body.read).first
      # generate thumbnail and compressed image
      generate_thumbnail File.join(thumb_dir, img_name), img
      generate_compressed File.join(compress_dir, img_name), img
    end

    # done!
    puts "All done!"
  end
  
  # download thumbnail to assets
  def generate_thumbnail name, img, path
    img_path = File.join path, name
    img = img.resize_to_fit 200,200
    img.write img_path
  end

  # download compressed image to assets
  def generate_compressed name, img, path
    img_path = File.join path, name
    img.write(img_path) { self.quality = 70 }
  end
end
