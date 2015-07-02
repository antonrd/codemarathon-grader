module ApplicationHelper
  def is_runs_page?
    defined?(@page_title) && @page_title == 'runs'
  end

  def is_tasks_page?
    defined?(@page_title) && @page_title == 'tasks'
  end

  def is_invites_page?
    defined?(@page_title) && @page_title == 'invites'
  end
end
