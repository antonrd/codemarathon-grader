#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com&run[task_id]=1&run[code]=update_task&run[data]=1" localhost:3030/runs --header "Authorization: Token token=\"8223fb5a81dd5ca98d267df6907d3cb3\""
