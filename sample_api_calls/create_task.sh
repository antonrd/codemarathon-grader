#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&task[name]=new task 1&task[description]=new statement 1&task[task_type]=iofiles" localhost:3030/tasks --header "Authorization: Token token=\"ca338c89b83f8a153f2f95149ff51e17\""
