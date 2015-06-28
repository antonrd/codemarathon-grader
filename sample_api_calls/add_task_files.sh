#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&run[task_id]=1&run[code]=update_task&run[data]=1" localhost:3030/runs --header "Authorization: Token token=\"ca338c89b83f8a153f2f95149ff51e17\""
