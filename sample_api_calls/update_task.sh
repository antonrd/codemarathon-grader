#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&task[name]=new task 1&task[description]=new statement 1&task[task_type]=iofiles&task_id=1" localhost:3030/tasks/1/update_task --header "Authorization: Token token=\"8223fb5a81dd5ca98d267df6907d3cb3\""
