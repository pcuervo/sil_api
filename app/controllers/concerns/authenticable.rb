module Authenticable

  # Devise methods overwrites
  def current_user user_token=''
    return @current_user if @current_user.present?

    user_token = UserToken.find_by(auth_token: user_token) 
    return nil if ! user_token.present?
    
    @current_user ||= User.find( user_token.user_id )
    #@current_user ||= User.find_by(auth_token: user_token)

    #@current_user ||= User.find_by(auth_token: request.headers['Authorization'])
  end

  def authenticate_with_token! user_token
    render json: { errors: "Not authenticated" },
                status: :unauthorized unless user_signed_in? user_token
  end

  def user_signed_in? user_token
    current_user(user_token).present?
  end

  def authenticate_user
    
  end
end