class Api::V1::ClientContactsController < ApplicationController
  respond_to :json

  def show
    c = ClientContact.find(params[:id])
    respond_with c
  end

  def index
    respond_with ClientContact.all
  end

  def create

    client_contact = ClientContact.new(client_contact_params)
    client_contact.role = User::CLIENT

    if client_contact.save
      log_action( current_user.id, 'ClientContact', 'Created client contact: "' + client_contact.first_name + ' ' + client_contact.last_name, client_contact.id )
      render json: client_contact, status: 201, location: [:api, client_contact] 
      return 
    end

    render json: { errors: client_contact.errors }, status: 422
    
  end

  def update
    client_contact = ClientContact.find(params[:id])
    client_contact.role = 4

    if client_contact.update(client_contact_params)
      log_action( current_user.id, 'ClientContact', 'Updated client contact: "' + client_contact.first_name + ' ' + client_contact.last_name, client_contact.id )
      render json: client_contact, status: 201, location: [:api, client_contact]
      return
    end

    render json: { errors: client_contact.errors }, status: 422
  end

  def destroy
    client_contact = ClientContact.find(params[:id])
    log_action( current_user.id, 'ClientContact', 'Deleted client contact: "' + client_contact.first_name + ' ' + client_contact.last_name, client_contact.id )
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

  private 

  def client_contact_params
    params.require(:client_contact).permit(:first_name, :last_name, :password, :password_confirmation, :phone, :phone_ext, :email, :business_unit, :client_id)
  end
end
