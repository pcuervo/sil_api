if Rails.env == "production"
  S3_CREDENTIALS = { :access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_SECRET_KEY'], :bucket => "sil-dev"} 

 else     
    S3_CREDENTIALS = Rails.root.join("config/s3.yml")
    puts S3_CREDENTIALS.to_yaml
end
