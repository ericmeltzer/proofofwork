ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 465,
  :domain => "gmail.com",
  :user_name => "prooftest487@gmail.com",
  :password => "testwork",
  :authentication => "plain",
  :enable_starttls_auto => true
}
