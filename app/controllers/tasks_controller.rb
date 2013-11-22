class TasksController < ApplicationController

  before_filter :restrict_access, except: [:index]

  def index
    @tasks = current_user.tasks
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user.nil?
      render inline: {status: 1, 
        message: "Invalid user email specified."}.to_json
      return
    end

    @task = @user.tasks.create(params[:task])

    if @task.save
      render inline: {status: 0, message: "New task created.", task_id: @task.id}.to_json
    else
      render inline: {status: 1, 
        message: "Failed to create a new task. Error: %s" % @task.errors.full_messages}.to_json
    end
  end
end
