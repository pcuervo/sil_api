class Api::V1::DeliveriesController < ApplicationController
  respond_to :json

  def show
    respond_with Delivery.find( params[:id] ).get_details
  end

  def index
    if params[:recent]
      deliveries = Delivery.recent
    else
      deliveries = Delivery.all
    end

    if 1 != params[:user_role].to_i && 4 != params[:user_role].to_i
      deliveries = deliveries.where( 'user_id = ?', current_user.id )
    end
    respond_with deliveries
  end

  def create
    @delivery_user = User.find( params[:user_id] )
    delivery = Delivery.new( delivery_params )
    @delivery_user.deliveries << delivery

    if [ User::PROJECT_MANAGER, User::ACCOUNT_EXECUTIVE, User::CLIENT ].include? @delivery_user.role
      delivery.status = Delivery::PENDING_APPROVAL
    end

    if delivery.save!
      items = params[:inventory_items]
      delivery.add_items( items, @delivery_user.first_name + ' ' + @delivery_user.last_name, params[:delivery][:additional_comments] )

      send_delivery_request_notifications if Delivery::PENDING_APPROVAL == delivery.status

      render json: delivery, status: 201, location: [:api, delivery]
    else
      render json: { errors: delivery.errors }, status: 422
    end
  end

  def update
    @delivery = Delivery.find(params[:id])
    previous_status = @delivery.status

    if params[:image]
      image = Paperclip.io_adapters.for(params[:image])
      image.original_filename = params[:filename]
      @delivery.image = image
    end

    if @delivery.update( delivery_params )
      send_delivery_approval_notifications if Delivery::PENDING_APPROVAL == previous_status
      render json: @delivery, status: 200, location: [:api, @delivery]
      return
    end

    render json: { errors: @delivery.errors }, status: 422
  end

  def pending_approval
    respond_with Delivery.pending_approval
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
    params.require(:delivery).permit( :delivery_user_id, :company, :address, :addressee, :addressee_phone, :image, :latitude, :longitude, :status, :additional_comments, :date_time, :supplier_id )
  end

  def send_delivery_request_notifications
    admins = User.where( 'role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ]  )
    admins.each do |admin|
      admin.notifications << Notification.create( :title => 'Solicitud de envío', :inventory_item_id => -1, :message => @delivery_user.get_role + ' "' + @delivery_user.first_name + ' ' + @delivery_user.last_name + '" ha solicitado un envío.' )
    end
  end 

  def send_delivery_approval_notifications
    user = @delivery.user
    user.notifications << Notification.create( :title => 'Aprobación de envío', :inventory_item_id => -1, :message => 'Se ha aprobado tu solicitud de envío.' )
  end 
end

