class Api::V1::ClientContactsController < ApplicationController
  respond_to :json

  def show
    c = ClientContact.find(params[:id])
    respond_with c
  end

  def index
    respond_with ClientContact.all.order(:created_at)
  end

  def create

    client_contact = ClientContact.new(client_contact_params)
    client_contact.role = User::CLIENT

    if client_contact.save
      render json: client_contact, status: 201, location: [:api, client_contact] 
      return 
    end

    render json: { errors: client_contact.errors }, status: 422
    
  end

  def update
    client_contact = ClientContact.find( params[:id] )
    client_contact.role = 4

    if client_contact.update(client_contact_params)
      render json: client_contact, status: 201, location: [:api, client_contact]
      return
    end

    render json: { errors: client_contact.errors }, status: 422
  end

  def destroy
    client_contact = ClientContact.find(params[:id])
    client_contact.destroy
    head 204
  end

  def get_by_client
    client_contacts = ClientContact.where('client_id = ?', params[:id] )
    respond_with client_contacts
  end

  def inventory_items
    user = User.find( params[:id] )
    client_contact = ClientContact.find( user.actable_id )
    respond_with client_contact.inventory_items
  end

  def stats
    stats = {}

    project_ids = []
    if 6 == current_user.role
      client_contact = ClientContact.find( current_user.actable_id )
    else
      client_contact = ClientContact.find( params[:id] )
    end
    client_contact.projects.each do |p|
      project_ids.push( p.id )
    end

    stats['inventory_by_type'] = InventoryItem.inventory_by_type( project_ids )
    stats['rent_by_month'] = client_contact.get_contact_rent_history
    stats['total_number_items'] = client_contact.inventory_items.count
    stats['total_high_value_items'] = client_contact.total_high_value_items

    render json: { stats: stats }, status: 200
  end

  private 

  def client_contact_params
    params.require(:client_contact).permit( :first_name, :last_name, :password, :password_confirmation, :phone, :phone_ext, :email, :business_unit, :client_id, :discount )
  end
end
