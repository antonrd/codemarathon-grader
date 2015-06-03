#!/bin/bash
url -X POST --data "email=dimitrov.anton@gmail.com&task[name]=new task 1&task[description]=new statement 1&task[task_type]=iofiles" localhost:3030/tasks --header "Authorization: Token token=\"8223fb5a81dd5ca98d267df6907d3cb3\""
