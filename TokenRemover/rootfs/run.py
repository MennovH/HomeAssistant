#!/usr/bin/env python3

import datetime as dt
import json
import sys
import os
from requests import post

AUTH_FILE = "/config/.storage/auth"

with open(AUTH_FILE, "r") as f:
    data = json.load(f)

lst = []
for k in data["data"]["refresh_tokens"]:
    if k["token_type"] != "normal":
        lst.append(k)
        continue
        
    str = k["created_at"]
    str = str[:str.index("T")].split("-")
    str = dt.datetime(int(str[0]), int(str[1]), int(str[2]))
    if str >= (dt.datetime.today() - dt.timedelta(days=int(sys.argv[1]))):
        lst.append(k)

if len(lst) < len(data["data"]["refresh_tokens"]):
    print(len(lst))
    print(len(data["data"]["refresh_tokens"]))
    
    data["data"]["refresh_tokens"] = lst

    with open(AUTH_FILE, "w") as f:
        json.dump(data, f, indent=4)

    #curl -X POST http://supervisor/core/restart -H "Authorization: Bearer $SUPERVISOR_TOKEN"

    os.system("curl -sSL -H \"Authorization: Bearer \$SUPERVISOR_TOKEN\" http://supervisor/core/restart")
    #url = "http://supervisor/core/restart"
    #headers = {
    #    "Authorization": "Bearer $SUPERVISOR_TOKEN",
    #}

    #response = post(url, headers=headers)
    #print(response.text)
        
        
    #os.system(f'curl -X POST http://supervisor/core/restart -H "Authorization: Bearer $SUPERVISOR_TOKEN"')
