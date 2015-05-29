module ApplicationHelper
  def is_runs_page?
    defined?(@runs)
  end

  def is_tasks_page?
    defined?(@tasks)
  end
end
