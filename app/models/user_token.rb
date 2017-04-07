class UserToken < ActiveRecord::Base
  after_create :delete_expired_tokens
  belongs_to :user

  def delete_expired_tokens
    return if ! self.user_id.present?

    user = User.find( self.user_id )
    return if ! user.present?
    
    if user.user_tokens.count > 5
      user.user_tokens.first.destroy
    end
  end
end
