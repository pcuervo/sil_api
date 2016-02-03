if Rails.env == "production"
  S3_CREDENTIALS = { :access_key_id => ENV['AWSAccessKeyId'], :secret_access_key => ENV['AWSSecretKey'], :bucket => ENV['S3_BUCKET_NAME']} 
 else     
    S3_CREDENTIALS = Rails.root.join("config/s3.yml")
end
