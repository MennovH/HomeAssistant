#!/usr/bin/env python3

# Import needed modules
# from datetime import timedelta, datetime
from datetime import datetime, time, timedelta

import json
import sys
import asyncio
import revoke

# Defining the auth file which will be updated if needed
AUTH_FILE = "/config/.storage/auth"


def addon(info):
    try:
        prt = info[info.index("TokenRemover"):]
        return prt[prt.index(":"):prt.index("description")][2:-3]
    except Exception as e:
        return e


def date_calc(date, weekday):
    d = datetime.strptime(date, '%Y-%m-%d')
    t = timedelta((7 + weekday - d.weekday()) % 7)
    return (d + t).strftime('%Y-%m-%d')


# def recurrence(am_pm, automation_time, weekdays):
#     # Calculate next run time
#     hr, mnt = int(automation_time[0]), int(automation_time[1])

#     if hr == 12 and am_pm == 'AM':
#         hr = 0
#     elif hr != 12 and am_pm == 'PM':
#         hr += 12
    
#     for date_value in sorted([date_calc(f'{datetime.now().date()}', day) for day in weekdays]):
#         date_list = date_value.split('-')
#         yr, mnth, d = int(date_list[0]), int(date_list[1]), int(date_list[2])
        
        
#         if am_pm == 'Both':
#             h = hr if hr < 12 else 0
#             for _ in range(2):
#                 if datetime.now() < datetime(year=yr, month=mnth, day=d, hour=h, minute=mnt, second=0):
#                     later = datetime(year=yr, month=mnth, day=d, hour=h, minute=mnt)
#                     print(later)
#                     return f"Scheduled: {later}\n{(later - datetime.now()).total_seconds()}"
#                 h = 12 if h == 0 else hr + 12
                    
#         else:
#             if datetime.now() < datetime(year=yr, month=mnth, day=d, hour=hr, minute=mnt, second=0):
#                 later = datetime(year=yr, month=mnth, day=d, hour=hr, minute=mnt)
#                 return f"Scheduled: {later}\n{(later - datetime.now()).total_seconds()}"


import sys
import json
from datetime import datetime, time, timedelta

def recurrence(days_enabled, automation_time, am_pm):
    now = datetime.now()
    hour_12, minute = map(int, automation_time.split(":"))

    def to_24h(hour, ampm):
        if ampm == "AM":
            return 0 if hour == 12 else hour
        elif ampm == "PM":
            return 12 if hour == 12 else hour + 12

    candidate_hours = []
    if am_pm in ("AM", "BOTH"):
        candidate_hours.append(to_24h(hour_12, "AM"))
    if am_pm in ("PM", "BOTH"):
        candidate_hours.append(to_24h(hour_12, "PM"))

    day_map = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    for offset in range(8):
        check_date = now + timedelta(days=offset)
        day_key = day_map[check_date.weekday()]

        if not days_enabled.get(day_key, False):
            continue

        for hour in sorted(candidate_hours):
            candidate = datetime.combine(
                check_date.date(),
                time(hour=hour, minute=minute)
            )

            if candidate > now:
                return "Next run:", candidate.strftime("%Y-%m-%d %H:%M")
                # return candidate

    return "Next run: not scheduled"


def tokenremover(long_lived_token, retention_days, active_days):
    # Read auth file contents to variable
    with open(AUTH_FILE, "r") as f:
        data = json.load(f)

    # Create empty list, this is where the "valid" tokens will be stored temporarily
    keep_list = []
    rem_tokens = []

    # loop through existing refresh tokens to filter the ones that need to be removed
    for token in data["data"]["refresh_tokens"]:
        # Only focus on "normal" tokens, and keep other tokens, e.g. "system" and "long lived"
        if token["token_type"] != "normal":
            keep_list.append(token["id"])
            continue
        
        if int(active_days) < 999:
            if token["last_used_at"] is None:
                continue

            date_str = token["last_used_at"]
            yr, mnth, d, hr, mnt, scnd = date_str[:date_str.index(".")].translate(date_str.maketrans("T:.", "---")).split("-")
            last_used_date = datetime(int(yr), int(mnth), int(d), int(hr), int(mnt))
        
            if last_used_date >= (datetime.now() + timedelta(minutes=30) - timedelta(days=int(active_days))):
                keep_list.append(token["id"])
                continue

        # Get creation date, and parse to a comparable format
        date_str = token["created_at"]
        yr, mnth, d, hr, mnt, scnd = date_str[:date_str.index(".")].translate(date_str.maketrans("T:.", "---")).split("-")
        creation_date = datetime(int(yr), int(mnth), int(d), int(hr), int(mnt))
        
        # Compare the creation date with the exact date time of x days ago
        # add 30 minutes to creation date, to prevent on boot execution (if enabled) to trigger hereafter
        if creation_date >= (datetime.now() + timedelta(minutes=30) - timedelta(days=int(retention_days))):
            keep_list.append(token["id"])
            continue
        rem_tokens.append(token["id"])


    if long_lived_token in [None,"None",""]:
        # Detect differences
        removed_tokens = len(data["data"]["refresh_tokens"]) - len(keep_list)
        if removed_tokens > 0:    
            data["data"]["refresh_tokens"] = keep_list
            # Overwrite refresh_token list in auth file
            with open(AUTH_FILE, "w") as f:
                json.dump(data, f, indent=4)

        
            # "send" return value to bash, so it will run the "ha core restart" command hereafter. The restart is
            # necessary to implement the changes, otherwise the updated file will be restored by Home Assistant RAM.
        
        return f"  > Removed {removed_tokens} token{'' if removed_tokens == 1 else 's'}" + "\n" + f"{'  > Restarting...' if removed_tokens > 0 else ''}"

    else:
        if len(rem_tokens) > 0:
            async def process_revocation():
                # tokens = build_tokens_to_revoke()

                results = await revoke.revoke_tokens(long_lived_token, rem_tokens)

                for r in results:
                    print(r) #nodig?

            return f"  > Removed {len(rem_tokens)} token{'' if len(rem_tokens) == 1 else 's'}" + "\n" + f"{'  > Restarting...' if len(rem_tokens) > 0 else ''}"


if __name__ == '__main__':

    if sys.argv[1] == '0':
        # Check recurrence
        # weekdays = [day-1 for day in range(len(sys.argv[5:])) if sys.argv[5:][day] == 'true']
        # print(sys.argv[2:])

        # result = recurrence(sys.argv[3], sys.argv[4].split(':'), weekdays)
        # ---- input parsing ----
        days_enabled = json.loads(sys.argv[4])
        am_pm = sys.argv[2]
        automation_time = sys.argv[3]  # bv "08:45"


        # ---- berekening ----
        result = recurrence(days_enabled, automation_time, am_pm)

        # ---- output ----
        # if next_run_dt:
            
        # else:
        #     print("Next run: not scheduled")




    elif sys.argv[1] == '1':
        # Run tokenremover       
        result = tokenremover(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        result = addon("".join(sys.argv[2:])) #change to 3

    print(result)
    sys.exit(0)
    
