#!/usr/bin/env python3

# Import needed modules
from datetime import timedelta, datetime
import json
import sys
import asyncio
# import revoke

# Defining the auth file which will be updated if needed


if __name__ == '__main__':
    print(sys.argv[0])
    print(sys.argv[1]) #action
    print(sys.argv[2]) #long_lived_token
    print(sys.argv[3]) #am_pm
    print(sys.argv[4]) #automation_time
    print(sys.argv[5:]) #weekdays
    # if sys.argv[1] == '0':
    #     # Check recurrence
    weekdays = [day-1 for day in range(len(sys.argv[5:])) if sys.argv[5:][day] in ['true',1]]
    print([day-1 for day in range(len([1,0,0,0,1,0,0])) if [1,0,0,0,1,0,0][day] in ['true',1]])
    print(weekdays)
    print(sys.argv[3], sys.argv[4].split(':'), weekdays)
    # elif sys.argv[1] == '1':
        # Run tokenremover       
        # result = tokenremover(sys.argv[2], sys.argv[3], sys.argv[4])
    # else:
        # result = addon("".join(sys.argv[2:])) #change to 3

    # print(result)
    # sys.exit(0)
    







import sys
import json
from datetime import datetime, time, timedelta

days_enabled = {
    "mon": True,
    "tue": False,
    "wed": True,
    "thu": False,
    "fri": True,
    "sat": True,
    "sun": False
}

def next_run(days_enabled, hour_12, minute, am_pm):
    now = datetime.now()

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
                return candidate

    return None



next_run(days_enabled, 9, 2, 'PM')