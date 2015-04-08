namespace :pictures do
  require 'fileutils'
  require 'rubygems'
  require 'zip'
  
  S3_BUCKET_NAME = ENV['S3_BUCKET_NAME'] || raise('please set environment var S3_BUCKET_NAME')

  desc 'Zip up compressed images'
  task :zip => :environment do
    generate_zip Rails.root.join('app','assets','images', 'compressed'), Rails.root.join('test.zip')
  end
  
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
    start_time = Time.now
    objects.each_with_index do |o,i|
      # get image filename
      img_name = o.object.key

      puts "Processing #{img_name} #{i}/#{num_objects} (#{i.to_f/num_objects*100}%)"
      
      next if File.extname(img_name).empty? # skip folder objects (non images)
      # skip files we've already processed        
      if File.exists? File.join(compress_dir, img_name)
        puts "Skipping #{img_name} since it already exists"
        next
      end

      # create RMagick image
      img = Magick::Image.from_blob(o.object.get.data.body.read).first
      # generate thumbnail and compressed image
      generate_thumbnail File.join(thumb_dir, img_name), img
      generate_compressed File.join(compress_dir, img_name), img
    end

    # generate zip file
    generate_zip compress_dir, Rails.root.join('app', 'assets', 'images.zip')

    # done!
    puts "All done!"
    puts "Total time taken was #{Time.now - start_time} seconds"
  end
  
  # download thumbnail to assets
  def generate_thumbnail path, img
    img = img.resize_to_fit 200,200
    img.write path
  end

  # download compressed image to assets
  def generate_compressed path, img
    img.write(path) { self.quality = 70 }
  end

  # zip files up so they can be downloaded all at once
  def generate_zip folder, zip_path
    puts File.join(folder, '*')
    input_files = Dir.glob(File.join(folder, '*'))
    
    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      input_files.each do |file|
        # Two arguments:
        # - The name of the file as it will appear in the archive
        # - The original file, including the path to find it
        zipfile.add(File.basename(file), file)
      end
    end
  end
end
