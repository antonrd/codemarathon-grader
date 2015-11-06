#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&task[name]=new task 1&task[description]=new statement 1&task[task_type]=iofiles" localhost:6543/tasks --header "Authorization: Token token=\"3177bfd8ddbbb6c902886ab2890099fb\""
