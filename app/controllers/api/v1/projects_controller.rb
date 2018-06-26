class Api::V1::ProjectsController < ApplicationController
  before_action only: [:create] do 
    authenticate_with_token! request.headers['Authorization']
  end

  respond_to :json

  def index
    respond_with Project.all.order(created_at: :desc)
  end
  
  def show
    if ! Project.exists?( params[:id] )
      render json: { errors: "No se encontró el proyecto." }, status: 422
      return
    end
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
    if project.destroy
      render json: project, status: 201, location: [:api, project]
      return
    end
    
    render json: { errors: ['No se puede eliminar un proyecto con inventario.'] }, status: 422
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

    contact_name = 'Sin Cliente asignado'
    if client_contact.present?
      contact_name = client_contact.first_name + ' ' + client_contact.last_name
    end
        
    client_obj = { :id => client.id, :name => client.name, :contact_name => contact_name }
    render json: { :client => client_obj }, status: 200, location: [:api, project]
  end

  def by_user
    user = User.find( params[:id] )
    projects = user.projects

    render json: { :projects => projects }, status: 200, location: [:api, user]
  end

  def add_users
    success_msg = 'Usuario(s) agregado(s) con éxito.'

    if ! params[:new_pm_id].present? and ! params[:new_ae_id].present?  and ! params[:client_contact_id]
      render json: { errors: ['Necesitas agregar al menos un Project Manager, Ejecutivo de Cuenta o Contato Cliente'] }, status: 422
      return
    end     

    project = Project.find( params[:project_id] )
    if params[:new_pm_id].present? 
      if project.users.where('user_id = ?', params[:new_pm_id]).count == 0 
        pm = User.find( params[:new_pm_id] )
        project.users << pm
      else
        
        success_msg = 'Ya existe el usuario en el proyecto.'
      end
    end
    if params[:new_ae_id].present? 
      if project.users.where('user_id = ?', params[:new_ae_id]).count == 0 
        ae = User.find( params[:new_ae_id] )
        project.users << ae
      else
        success_msg = 'Ya existe el usuario en el proyecto.'
      end
    end
    if params[:client_contact_id].present? 
      if project.users.where('user_id = ?', params[:client_contact_id]).count == 0 
        client_contact = User.find( params[:client_contact_id] )
        project.users << client_contact
      else
        success_msg = 'Ya existe el usuario en el proyecto.'
      end
    end

    if project.save!
      render json: { :success => success_msg }, status: 201, location: [:api, project]
      return
    end

    render json: { errors: ['No se pudo agregar el usuario al proyecto'] }, status: 422
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
