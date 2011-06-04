# -*- encoding : utf-8 -*-
module Settings
  class BlocksController < ApplicationController
    before_filter :login_required
    # privilege_required :edit_blocks
    respond_to :html, :xml, :js
    
    def index
      @blocks = Block.order(:position)
    end
    
    def new
      # FIXME: page_id should always point to the id of the 'index' page, where all the blocks should be displayed
      @block = Block.new(:page_id => "15")
    end
    
    def create
      @block = Block.new(params[:block])
      if @block.save
        redirect_to settings_blocks_path
      else
        render :action => "new"
      end
    end
    
    def show
      redirect_to edit_settings_block_path(params[:id])
    end
    
    def edit
      @block = Block.find_by_name!(params[:id])
    end
    
    def update
      @block = Block.find_by_name(params[:id])
      if @block.update_attributes(params[:block])
        redirect_to settings_blocks_path
      else
        render :action => "edit"
      end
    end
    
    def destroy
      block = Block.find(params[:id])
      block.destroy
      respond_with block, :location => settings_blocks_path
    end
    
    def update_positions
      blocks = Block.all
      blocks.each do |block|
        new_index = params[:blocks].index(block.id.to_s)
        block.update_attribute(:position, new_index+1) if new_index
      end
      render :nothing => true
    end
    
    private
    def init_menu
      @submenu_partial = "settings"
    end
  end
end
