require 'spec_helper'

RSpec.describe Api::V1::NotificationsController, type: :controller do
  describe "GET #index" do
    before(:each) do
      user = FactoryGirl.create :user
      3.times{ FactoryGirl.create :notification }

      api_authorization_header user.auth_token
      current_user = User.find_by(auth_token: request.headers['Authorization'])

      Notification.all.each do |n|
        current_user.notifications << n
      end

      get :index
    end

    it "returns all unread notifications for current user" do
      notification_response = json_response[:notifications]
      expect( notification_response.count ).to eql 3
    end

    it { should respond_with 200 }
  end

  describe "GET #get_unread" do
    before(:each) do
      user = FactoryGirl.create :user
      3.times{ FactoryGirl.create :notification }
      read_notification = Notification.first
      read_notification.status = Notification::READ
      read_notification.save

      api_authorization_header user.auth_token
      current_user = User.find_by(auth_token: request.headers['Authorization'])

      Notification.all.each do |n|
        current_user.notifications << n
      end

      get :get_unread
    end

    it "returns all unread notifications for current user" do
      notification_response = json_response[:notifications]
      expect( notification_response.count ).to eql 2
    end

    it { should respond_with 200 }
  end

  describe "GET #get_num_unread" do
    before(:each) do
      user = FactoryGirl.create :user
      3.times{ FactoryGirl.create :notification }
      read_notification = Notification.first
      read_notification.status = Notification::READ
      read_notification.save

      api_authorization_header user.auth_token
      current_user = User.find_by(auth_token: request.headers['Authorization'])

      Notification.all.each do |n|
        current_user.notifications << n
      end

      get :get_num_unread
    end

    it "returns number of all unread notifications for current user" do
      notification_response = json_response[:unread_notifications]
      expect( notification_response ).to eql 2
    end

    it { should respond_with 200 }
  end

  describe "GET #get_read" do
    before(:each) do
      user = FactoryGirl.create :user
      3.times{ FactoryGirl.create :notification }
      read_notification = Notification.first
      read_notification.status = Notification::READ
      read_notification.save

      api_authorization_header user.auth_token
      current_user = User.find_by(auth_token: request.headers['Authorization'])

      Notification.all.each do |n|
        current_user.notifications << n
      end

      get :get_read
    end

    it "returns all unread notifications for current user" do
      notification_response = json_response[:notifications]
      expect( notification_response.count ).to eql 1
    end

    it { should respond_with 200 }
  end

  describe "POST #destroy" do
    context "when Notification is succesfully destroyed" do
      before(:each) do
        user = FactoryGirl.create :user
        notification = FactoryGirl.create :notification
        api_authorization_header user.auth_token
        post :destroy, id: notification.id
      end

      it { should respond_with 204 }
    end
  end

  describe "POST #mark_as_read" do
    before(:each) do
      user = FactoryGirl.create :user
      5.times{ FactoryGirl.create :notification }

      api_authorization_header user.auth_token
      current_user = User.find_by(auth_token: request.headers['Authorization'])
      Notification.all.each { |n| current_user.notifications << n }

      post :mark_as_read
    end

    it "should mark all Notifications as read" do
      unread = Notification.unread
      expect( unread.count ).to eql 0
    end

    it { should respond_with 204 }
  end

end
