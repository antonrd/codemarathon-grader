class TasksController < ApplicationController

  before_filter :restrict_access, except: [:index, :show, :upload_tests, :delete_tests, :delete_test]
  before_filter :authenticate_user!, except: [:create, :update_task]

  def index
    @page_title = 'tasks'
    @tasks = current_user.tasks
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user.nil?
      render inline: {status: 1,
        message: "Invalid user email specified."}.to_json
      return
    end

    @task = @user.tasks.create(task_params)

    if @task.save
      render inline: {status: 0, message: "New task created.", task_id: @task.id}.to_json
    else
      render inline: {status: 1,
        message: "Failed to create a new task. Error: %s" % @task.errors.full_messages}.to_json
    end
  end

  def update_task
    @user = User.find_by_email(params[:email])
    if @user.nil?
      render inline: {status: 1,
        message: "Invalid user email specified."}.to_json
      return
    end

    @task = @user.tasks.find_by_id(params[:task_id])

    if @task.update_attributes(task_params)
      render inline: {status: 0, message: "Task updated.", task_id: @task.id}.to_json
    else
      render inline: {status: 1,
        message: "Failed to update task. Error: %s" % @task.errors.full_messages}.to_json
    end
  end

  def show
    @task = Task.find(params[:id])
    @tests = TaskFileManager.new(@task).file_list
  end

  def upload_tests
    @task = Task.find(params[:id])
    TaskFileManager.new(@task).upload_tests(params[:task][:test_cases]) if !params[:task][:test_cases].blank?
    redirect_to task_path(@task)
  end

  def delete_tests
    @task = Task.find(params[:id])
    TaskFileManager.new(@task).delete_tests
    redirect_to task_path(@task)
  end

  def delete_test
    @task = Task.find(params[:id])
    TaskFileManager.new(@task).delete_test(params[:file_name])
    redirect_to task_path(@task)
  end

  protected

  def task_params
    params.require(:task).permit(:name, :description, :task_type, :wrapper_code)
  end
end
