class RunsController < ApplicationController

  before_filter :restrict_access, except: [:index]
  before_filter :authenticate_user!, only: [:index]

  def index
    @page_title = 'runs'
    @runs = current_user.runs.latest_first.page(params[:page]).per(20)
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user.nil?
      reply = {status: 1, message: "Invalid user email specified."}
      render inline: reply.to_json
      return
    end

    @run = @user.runs.create(run_params)

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
      render inline: @run.description.to_json
    end
  end

  private

  def run_params
    params.require(:run).permit(:task_id, :code, :data, :max_memory_kb, :max_time_ms)
  end
end
