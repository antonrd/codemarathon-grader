#!/bin/bash
curl -X POST --data "email=dimitrov.anton@gmail.com" localhost:3030/runs/1/resubmit --header "Authorization: Token token=\"8223fb5a81dd5ca98d267df6907d3cb3\""
