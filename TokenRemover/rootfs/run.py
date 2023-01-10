#!/usr/bin/env python3

# import needed modules
import datetime as dt
import json
import sys

# defining the auth file which will be updated if needed
AUTH_FILE = "/config/.storage/auth"

# read auth file contents to variable
with open(AUTH_FILE, "r") as f:
    data = json.load(f)

# create empty list, this is where the "valid" tokens will be stored temporarily
keep_list = []

# loop through existing refresh tokens to filter the ones that need to be removed
for token in data["data"]["refresh_tokens"]:
    
    # only focus on "normal" tokens, and keep other tokens, e.g. "system" and "long lived"
    if token["token_type"] != "normal":
        keep_list.append(token)
        continue
    
    # get creation date, and parse to a comparable format
    creation_str = token["created_at"]
    year, month, day, hour, minute, second = creation_str[:creation_str.index(".")].translate(creation_str.maketrans("T:.", "---")).split("-")
    creation_date = dt.datetime(int(year), int(month), int(day), int(hour), int(minute))
    
    # compare the creation date with the exact date time of x days ago
    # add 30 minutes to creation date, to prevent on boot execution (if enabled) to trigger hereafter
    if creation_date >= (dt.datetime.now() + dt.timedelta(minutes=30) - dt.timedelta(days=int(sys.argv[1]))):
        keep_list.append(token)

# verify differences
removed_tokens = len(data["data"]["refresh_tokens"]) - len(keep_list)
if removed_tokens > 0:    
    data["data"]["refresh_tokens"] = keep_list
    
    # overwrite refresh_token list in auth file
    with open(AUTH_FILE, "w") as f:
        json.dump(data, f, indent=4)
    
    # "send" return value to bash, so it will run the "ha core restart" command hereafter. The restart is
    # necessary to implement the changes, otherwise the updated file will be restored by Home Assistant RAM.
    print(f"Home Assistant Core will now restart to remove {removed_tokens} token{'' if removed_tokens == 1 else 's'}")
else:
    print(f"No tokens older than {sys.argv[1]} day{'' if sys.argv[1] == 1 else 's'} were found")
    
sys.exit(0)
