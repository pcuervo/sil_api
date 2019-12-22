# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < ApplicationController
      before_action only: [:create] do
        authenticate_with_token! request.headers['Authorization']
      end
      before_action only: %i[transfer_inventory transfer_inventory_items] do
        set_transfer_projects
      end
      before_action only: %i[inventory lean_show show clean_inventory] do
        set_project
      end

      respond_to :json

      def index
        respond_with Project.all.order(created_at: :desc)
      end

      def show
        unless @project
          render json: { errors: 'No se encontró el proyecto.' }, status: 422
          return
        end

        render json: @project, include: ['inventory_items', 'inventory_items.item_locations']
      end

      def lean_index
        render json: Project.all.order(name: :asc), each_serializer: LeanProjectSerializer
      end


      def create
        account_executive = User.find_by_id(params[:ae_id])

        if account_executive.nil?
          render json: { errors: 'No se encontró la información del Ejecutivo de Cuenta.' }, status: 422
          return
        end

        project = Project.new(project_params)

        if project.save
          project.users << account_executive
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
        if project.destroy!
          render json: project, status: 201, location: [:api, project]
          return
        end

        render json: { errors: ['No se puede eliminar un proyecto con inventario.'] }, status: 422
      end

      def project_users
        project = Project.find(params[:id])
        project_users = project.users

        users = []
        project_users.each do |pu|
          user_obj = { id: pu.id, name: pu.first_name + ' ' + pu.last_name, role: pu.role }
          users.push(user_obj)
        end

        render json: { users: users }, status: 200, location: [:api, project]
      end

      def project_client
        project = Project.find(params[:id])
        client = project.client

        contact_name = 'Sin Cliente asignado'

        client_obj = { id: client.id, name: client.name, contact_name: contact_name }
        render json: { client: client_obj }, status: 200, location: [:api, project]
      end

      def by_user
        user = User.find(params[:id])
        projects = user.projects

        respond_with projects
      end

      def add_users
        success_msg = 'Usuario(s) agregado(s) con éxito.'

        if !params[:new_ae_id].present?
          render json: { errors: ['Necesitas agregar al menos un Ejecutivo de Cuenta'] }, status: 422
          return
        end

        project = Project.find(params[:project_id])
        if params[:new_ae_id].present?
          if project.users.where('user_id = ?', params[:new_ae_id]).count.zero?
            ae = User.find(params[:new_ae_id])
            project.users << ae
          else
            success_msg = 'Ya existe el usuario en el proyecto.'
          end
        end

        if project.save!
          render json: { success: success_msg }, status: 201, location: [:api, project]
          return
        end

        render json: { errors: ['No se pudo agregar el usuario al proyecto'] }, status: 422
      end

      def remove_user
        project = Project.find(params[:project_id])
        user = User.find(params[:user_id])
        if project.users.delete(user)
          render json: { success: 'Se ha eliminado el usuario "' + user.first_name + ' ' + user.last_name + '" del proyecto.' }, status: 200, location: [:api, project]
          return
        end

        render json: { errors: 'No se pudo eliminar el usuario del proyecto' }, status: 422
      end

      def transfer_inventory
        unless @project_from && @project_to
          render json: { errors: 'No existe el proyecto fuente o destino' }, status: 422
          return
        end

        @project_from.transfer_inventory(@project_to)
        render json: { success: 'Se ha transferido el proyecto con éxito' }, status: 200, location: [:api, @project_from]
      end

      def transfer_inventory_items
        unless @project_from && @project_to
          render json: { errors: 'No existe el proyecto fuente o destino' }, status: 422
          return
        end

        @project_from.transfer_inventory_items(@project_to, params[:items_ids])
        render json: { success: 'Se ha transferido el inventario con éxito' }, status: 200, location: [:api, @project_from]
      end

      def inventory
        unless @project
          render json: { errors: 'No existe el proyecto' }, status: 422
          return
        end

        render json: @project.inventory_items, status: 200
      end

      def clean_inventory
        unless @project
          render json: { errors: 'No existe el proyecto' }, status: 422
          return
        end

        InventoryCleaner::by_project(@project)
        render json: {success: "¡Se ha reiniciado el inventario del proyecto #{@project.name} correctamente!"}, status: 200
      end
      
      private

      def project_params
        params.require(:project).permit(:name, :litobel_id, :user_id, :client_id)
      end

      def set_transfer_projects
        @project_from = Project.find_by(id: params[:from_project_id])
        @project_to = Project.find_by(id: params[:to_project_id])
      end

      def set_project
        @project = Project.find_by(id: params[:id])
      end
    end
  end
end
