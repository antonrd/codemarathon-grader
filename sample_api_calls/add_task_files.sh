#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&run[task_id]=1&run[code]=update_task&run[data]=1" localhost:6543/runs --header "Authorization: Token token=\"3177bfd8ddbbb6c902886ab2890099fb\""
