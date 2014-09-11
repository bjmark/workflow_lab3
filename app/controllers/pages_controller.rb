class PagesController < ApplicationController
  def show
    case params[:id]
    when 'ui_xedit2'
      render params[:id], :layout => 'application2'
    else
      render params[:id]
    end
  end
end
