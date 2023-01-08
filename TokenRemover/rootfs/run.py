#!/usr/bin/env python3
#!/usr/bin/env bashio

import datetime as dt
import json
import sys

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
    #print(len(lst))
    #print(len(data["data"]["refresh_tokens"]))
    
    data["data"]["refresh_tokens"] = lst

    with open(AUTH_FILE, "w") as f:
        json.dump(data, f, indent=4)

print("restart")
sys.exit(0)
