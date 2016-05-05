class Api::V1::DeliveriesController < ApplicationController
  respond_to :json

  def show
    respond_with Delivery.find( params[:id] ).get_details
  end

  def index
    if params[:recent]
      respond_with Delivery.recent
      return
    end
    respond_with Delivery.all
  end

  def create
    delivery_user = User.find( params[:user_id] )
    delivery = Delivery.new( delivery_params )
    delivery_user.deliveries << delivery


    if delivery.save!
      items = params[:inventory_items]
      delivery.add_items( items, delivery_user.first_name + ' ' + delivery_user.last_name, params[:delivery][:additional_comments] )
      render json: delivery, status: 201, location: [:api, delivery]
    else
      render json: { errors: delivery.errors }, status: 422
    end
  end

  def update
    delivery = Delivery.find(params[:id])

    if params[:image]
      image = Paperclip.io_adapters.for(params[:image])
      image.original_filename = params[:filename]
      delivery.image = image
    end

    if delivery.update( delivery_params )
      render json: delivery, status: 200, location: [:api, delivery]
      return
    end

    render json: { errors: delivery.errors }, status: 422
  end

  def stats
    stats = {}

    shipped = Delivery.shipped.count
    delivered = Delivery.delivered.count
    rejected = Delivery.rejected.count

    stats['shipped'] = shipped 
    stats['delivered'] = delivered 
    stats['rejected'] = rejected 

    render json: { stats: stats }, status: 200
  end

  private 

  def delivery_params
    params.require(:delivery).permit( :delivery_user_id, :company, :address, :addressee, :addressee_phone, :image, :latitude, :longitude, :status, :additional_comments )
  end
end

