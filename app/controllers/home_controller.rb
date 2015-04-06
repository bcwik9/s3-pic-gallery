class HomeController < ApplicationController
  ASSETS_DIR = File.join 'app', 'assets', 'images'

  def index
    # iterate through pictures and map thumbnails to compressed images
    @pics = {}
    Dir.glob(File.join(ASSETS_DIR, 'thumbnails', '*')).each do |pic|
      basename = File.basename pic
      @pics[File.join('thumbnails', basename)] = root_path + basename
    end
  end

  def show
    @pic = File.join('compressed', "#{params[:pic_name]}.#{params[:format]}")
  end
end
