class UserToken < ActiveRecord::Base
  after_create :delete_expired_tokens
  belongs_to :user

  def delete_expired_tokens
    user = User.find( self.user_id )
    if user.user_tokens.count > 5
      user.user_tokens.first.destroy
    end
  end
end
