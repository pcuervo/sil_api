module Api
  module V1
    class LogsController < ApplicationController
      respond_to :json

      def index
        respond_with Log.all.order(created_at: :desc)
      end
    end
  end
end
