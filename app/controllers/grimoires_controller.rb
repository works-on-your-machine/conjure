class GrimoiresController < ApplicationController
  before_action :set_grimoire, only: [ :show, :edit, :update, :destroy, :duplicate ]

  def index
    @grimoires = Grimoire.all
  end

  def show
  end

  def new
    @grimoire = Grimoire.new
  end

  def create
    @grimoire = Grimoire.new(grimoire_params)
    if @grimoire.save
      redirect_to @grimoire
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @grimoire.update(grimoire_params)
      redirect_to @grimoire
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def duplicate
    copy = @grimoire.dup
    copy.name = "#{@grimoire.name} (copy)"
    copy.projects_count = 0
    copy.save!
    redirect_to edit_grimoire_path(copy)
  end

  def destroy
    @grimoire.destroy
    redirect_to grimoires_path
  end

  private

  def set_grimoire
    @grimoire = Grimoire.find(params[:id])
  end

  def grimoire_params
    params.require(:grimoire).permit(:name, :description)
  end
end
