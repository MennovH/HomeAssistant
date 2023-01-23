#!/usr/bin/env python3

# Import needed modules
from datetime import timedelta, datetime
import json
import sys

# Defining the auth file which will be updated if needed
AUTH_FILE = "/config/.storage/auth"


def addon(info):
    return info
    
    prt = info[info.index("TEST_TokenRemover"):]
    return prt[prt.index(": "):prt.index("\", \"description")][3:]


def date_calc(date, weekday):
    d = datetime.strptime(date, '%Y-%m-%d')
    t = timedelta((7 + weekday - d.weekday()) % 7)
    return (d + t).strftime('%Y-%m-%d')


def recurrence(am_pm, automation_time, weekdays):
    # Calculate next run time
    hr, mnt = int(automation_time[0]), int(automation_time[1])

    if hr == 12 and am_pm == 'AM':
        hr = 0
    elif hr != 12 and am_pm == 'PM':
        hr += 12
    
    for date_value in sorted([date_calc(f'{datetime.now().date()}', day) for day in weekdays]):
        date_list = date_value.split('-')
        yr, mnth, d = int(date_list[0]), int(date_list[1]), int(date_list[2])
        
        
        if am_pm == 'Both':
            h = hr if hr < 12 else 0
            for _ in range(2):
                if datetime.now() < datetime(year=yr, month=mnth, day=d, hour=h, minute=mnt, second=0):
                    later = datetime(year=yr, month=mnth, day=d, hour=h, minute=mnt)
                    return f"Next run at {later}\n{(later - datetime.now()).total_seconds()}"
                h = 12 if h == 0 else hr + 12
                    
        else:
            if datetime.now() < datetime(year=yr, month=mnth, day=d, hour=hr, minute=mnt, second=0):
                later = datetime(year=yr, month=mnth, day=d, hour=hr, minute=mnt)
                return f"Next run at {later}\n{(later - datetime.now()).total_seconds()}"


def tokenremover(retention_days, active_days):
    # Read auth file contents to variable
    with open(AUTH_FILE, "r") as f:
        data = json.load(f)

    # Create empty list, this is where the "valid" tokens will be stored temporarily
    keep_list = []

    # loop through existing refresh tokens to filter the ones that need to be removed
    for token in data["data"]["refresh_tokens"]:
        
        # Only focus on "normal" tokens, and keep other tokens, e.g. "system" and "long lived"
        if token["token_type"] != "normal":
            keep_list.append(token)
            continue
        
        if int(active_days) < 999:
            date_str = token["last_used_at"]
            yr, mnth, d, hr, mnt, scnd = date_str[:date_str.index(".")].translate(date_str.maketrans("T:.", "---")).split("-")
            last_used_date = datetime(int(yr), int(mnth), int(d), int(hr), int(mnt))
        
            if last_used_date >= (datetime.now() + timedelta(minutes=30) - timedelta(days=int(active_days))):
                keep_list.append(token)
                continue

        # Get creation date, and parse to a comparable format
        date_str = token["created_at"]
        yr, mnth, d, hr, mnt, scnd = date_str[:date_str.index(".")].translate(date_str.maketrans("T:.", "---")).split("-")
        creation_date = datetime(int(yr), int(mnth), int(d), int(hr), int(mnt))
        
        # Compare the creation date with the exact date time of x days ago
        # add 30 minutes to creation date, to prevent on boot execution (if enabled) to trigger hereafter
        if creation_date >= (datetime.now() + timedelta(minutes=30) - timedelta(days=int(retention_days))):
            keep_list.append(token)

    # Detect differences
    removed_tokens = len(data["data"]["refresh_tokens"]) - len(keep_list)
    if removed_tokens > 0:    
        data["data"]["refresh_tokens"] = keep_list
        
        # Overwrite refresh_token list in auth file
        with open(AUTH_FILE, "w") as f:
            json.dump(data, f, indent=4)
        
        # "send" return value to bash, so it will run the "ha core restart" command hereafter. The restart is
        # necessary to implement the changes, otherwise the updated file will be restored by Home Assistant RAM.
    
    return f" -> Removed {removed_tokens} token{'' if removed_tokens == 1 else 's'}" + "\n" + f"{' -> Restarting...' if removed_tokens >0 else ''}"
    

if __name__ == '__main__':    
    if sys.argv[1] == '0':
        # Check recurrence
        weekdays = [day-1 for day in range(len(sys.argv[3:])) if sys.argv[3:][day] == 'true']
        result = recurrence(sys.argv[2], sys.argv[3].split(':'), weekdays)
    elif sys.argv[1] == 1:
        # Run tokenremover       
        result = tokenremover(sys.argv[2], sys.argv[3])
    else:
        result = addon(sys.argv[2:])

    print(result)
    sys.exit(0)
    
