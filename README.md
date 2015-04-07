## Installation
* set up AWS CLI, and credentials
* Rmagick requires some extra libraries: sudo apt-get install imagemagick libmagickwand-dev
* bundle install
* set environment var S3_BUCKET_NAME to whatever bucket you want to process images out of
* run rake pictures:import
* bundle exec rails server, and you're done!
