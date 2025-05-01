class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@quierorecordarte.com.ar'
  layout 'mailer'
  
  private
  
  def base_url
    if Rails.env.production?
      'https://quierorecordarte.com.ar'
    else
      'http://localhost:3000'
    end
  end
end