# frozen_string_literal: true

FactoryBot.define do
  factory :log do
    sys_module { 'Users' }
    action { 'Create' }
    actor_id { '1' }
    user
  end
end
