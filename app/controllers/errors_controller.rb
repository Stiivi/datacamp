class ErrorsController < ApplicationController
  def create
    ErrorsMailer.error_report_mail(current_user, request.referrer, params[:title], params[:description]).deliver
    flash[:notice] = t('report_error.notice')
    redirect_to :back
  end
end
