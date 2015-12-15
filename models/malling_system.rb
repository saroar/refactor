class MallingSystem < ActiveRecord::Base
  def mailing_refactor(params)
    @from_user = User.find(params[:mailing_system][:user_id])
    case
    when @from_user.is_admin? || (@from_user.is_consultant? && @from_user.is_client?)
      emails = []
      chats = []
      if params[:mailing_system][:to_clients] == '1'
        to_clients(params[:mailing_system])
        emails = @emails
        chats = @chats
      end
      if params[:mailing_system][:to_consultants] == '1'
        to_consultants(params[:mailing_system])
        @emails = (@emails + emails).uniq if params[:mailing_system][:email] == '1'
        @chats = (@chats + chats).uniq if params[:mailing_system][:chat] == '1'
      end
    when @from_user.is_consultant? && params[:mailing_system][:to_clients] == '1'
      to_clients(params[:mailing_system])
    when @from_user.is_client? && params[:mailing_system][:to_consultants] == '1'
      to_consultants(params[:mailing_system])
    end
  end
end
