class Admin::MailingSystemsController < AdminController
  include ActionView::Helpers::TextHelper

  mattr_accessor :jobs_ids do
    []
  end

  def index
    @mailing_system = MailingSystem.new
  end

  def create
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

    if params[:button] == 'reach'
      @mailing_system = MailingSystem.new(permit_params)
      render 'index'
    else
      send_emails_messages(@emails, params[:mailing_system]) if params[:mailing_system][:email] == '1'
      send_chats_messages(@chats, params[:mailing_system]) if params[:mailing_system][:chat] == '1'
      redirect_to admin_mailing_systems_path
    end
  end


  private

  def send_chats_messages(chats, params)
    jobs_ids << chats.map { |user| SendChatsMessages.create(to: user, from: params[:user_id],
                                                            body: simple_format(params[:message])) } if chats.present?
  end

  def send_emails_messages(emails, params)
    jobs_ids << emails.map { |email| SendEmailsMessages.create(email: email, subject: params[:subject],
                                                               body: params[:message], from: params[:user_id]) } if emails.present?
  end

  def users
    users = ::Search::ClientsQuery.new.search.with_exact_countries_ids(params[:country_id])
    .with_migration_approaches_ids(params[:migration_approach_id])
  end

  def to_clients(params)
    users
    @emails = create_lists_emails(users) if params[:email] == '1'
    @chats = create_lists_chats(users) if params[:chat] == '1'
  end

  def to_consultants(params)
    users
    @emails = create_lists_emails(users) if params[:email] == '1'
    @chats = create_lists_chats(users) if params[:chat] == '1'
  end

  def create_lists_chats(users)
    users.to_a.map(&:id)
  end

  def create_lists_emails(users)
    users.to_a.map { |user| user.email if user.email.present? }.compact
  end

  def values_for_select
    @users = User.all
    @countries = Country.all
    @migration_apps = MigrationApproach.all
  end

  def permit_params
    params.require(:mailing_system).permit(:email, :chat, :user_id, :to_clients, :to_consultants,
    :country_id, :migration_approach_id, :subject, :message)
  end
end
