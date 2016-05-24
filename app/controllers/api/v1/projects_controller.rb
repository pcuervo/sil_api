class Api::V1::ProjectsController < ApplicationController
  before_action :authenticate_with_token!, only: [:create]

  respond_to :json

  def index
    respond_with Project.all.order(created_at: :desc)
  end
  
  def show
    respond_with Project.find( params[:id] )
  end

  def create
    client_contact = User.find_by_actable_id(params[:client_contact_id])
    project_manager = User.find_by_id(params[:pm_id])
    account_executive = User.find_by_id(params[:ae_id])

    if client_contact.nil?
      render json: { errors: "No se encontró la información de contacto del cliente." }, status: 422
      return
    end

    if project_manager.nil? or account_executive.nil?
      render json: { errors: "No se encontró la información del Project Manager o Ejecutivo de Cuenta." }, status: 422
      return
    end

    project = Project.new(project_params)

    if project.save
      
      project.users << project_manager
      project.users << account_executive
      project.users << client_contact
      render json: project, status: 201, location: [:api, project]
      return
    end

    render json: { errors: project.errors }, status: 422
  end

  def update
    project = Project.find(params[:id])

    if project.update(project_params)
      render json: project, status: 200, location: [:api, project]
      return
    end

    render json: { errors: project.errors }, status: 422
  end

  def destroy
    project = Project.find(params[:id])
    project.destroy
    head 204
  end 

  def get_project_users
    project = Project.find( params[:id] )
    project_users = project.users

    users = []
    project_users.each do |pu| 
      user_obj = { :id => pu.id, :name => pu.first_name + ' ' + pu.last_name, :role => pu.role }
      users.push( user_obj )
    end

    render json: { :users => users }, status: 200, location: [:api, project]
  end

  def get_project_client
    project = Project.find( params[:id] )
    client = project.client
    client_contact = project.users.find_by_role( User::CLIENT )

    client_obj = { :id => client.id, :name => client.name, :contact_name => client_contact.first_name + ' ' + client_contact.last_name }
    render json: { :client => client_obj }, status: 200, location: [:api, project]
  end

  def by_user
    user = User.find( params[:id] )
    projects = user.projects

    render json: { :projects => projects }, status: 200, location: [:api, user]
  end

  def add_users
    if ! params[:new_pm_id].present? and ! params[:new_ae_id].present? 
      render json: { errors: 'Necesitas agregar al menos un Project Manager o Ejecutivo de Cuenta' }, status: 422
      return
    end     
    project = Project.find( params[:project_id] )
    if params[:new_pm_id].present? 
      pm = User.find( params[:new_pm_id] )
      project.users << pm
    end
    if params[:new_ae_id].present? 
      ae = User.find( params[:new_ae_id] )
      project.users << ae
    end
    
    if project.save!
      render json: { :success => 'Usuario(s) agregado(s) con éxito.' }, status: 201, location: [:api, project]
      return
    end

    render json: { errors: 'No se pudo agregar el usuario al proyecto' }, status: 422
  end

  def remove_user
    project = Project.find( params[:project_id] )
    user = User.find( params[:user_id] )
    if project.users.delete( user )
      render json: { :success => 'Se ha eliminado el usuario "' + user.first_name + ' ' + user.last_name + '" del proyecto.'  }, status: 200, location: [:api, project]
      return
    end

    render json: { errors: 'No se pudo eliminar el usuario del proyecto' }, status: 422
  end 


  private

    def project_params
      params.require(:project).permit(:name, :litobel_id, :user_id, :client_id)
    end
end
