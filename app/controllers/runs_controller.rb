class RunsController < ApplicationController
  before_filter :restrict_access, except: [:index]

  def index
    @runs = current_user.runs.latest_first
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user.nil?
      reply = {status: 1, message: "Invalid user email specified."}
      render inline: reply.to_json
      return
    end

    @run = @user.runs.create(params[:run])

    if @run.save
      reply = {run_id: @run.id, status: 0, message: "New run created successfully."}
      render inline: reply.to_json
    else
      reply = {status: 1, message: "Failed to create a new task. Error: %s" % @run.errors.full_messages}
      render inline: reply.to_json
    end
  end

  def resubmit
    @user = User.find_by_email(params[:email])
    if @user.nil?
      reply = {status: 1, message: "Invalid user email specified."}
      render inline: reply.to_json
      return
    end

    @run = @user.runs.find_by_id(params[:id])

    if @run.nil?
      render inline: {status: 1, message: "Invalid run ID specified."}.to_json
    else
      @run.update_attribute(:status, Run::STATUS_PENDING)
      render inline: {status: 0}.to_json
    end
  end

  def show
    @user = User.find_by_email(params[:email])
    if @user.nil?
      reply = {status: 1, message: "Invalid user email specified."}
      render inline: reply.to_json
      return
    end

    @run = @user.runs.find_by_id(params[:id])

    if @run.nil?
      render inline: {status: 1, message: "Invalid run ID specified."}.to_json
    else
      render inline: {status: 0, run_status: @run.status, run_message: @run.message, run_log: @run.log}.to_json
    end
  end
end
