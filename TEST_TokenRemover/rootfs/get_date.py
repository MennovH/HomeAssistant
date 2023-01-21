#!/usr/bin/env python3

# import needed modules
from datetime import timedelta, datetime
import sys

        
def get_next_weekday(startdate, weekday):
    """
    @startdate: given date, in format '2013-05-25'
    @weekday: week day as a integer, between 0 (Monday) to 6 (Sunday)
    """
    d = datetime.strptime(startdate, '%Y-%m-%d')
    t = timedelta((7 + weekday - d.weekday()) % 7)
    return (d + t).strftime('%Y-%m-%d')


DAYS = []
num = -1
for day in sys.argv[2:]:
    num+=1
    if day == "true":
        DAYS.append(num)
        
AUTOMATION_TIME=sys.argv[1].split(":")
HOUR, MINUTE = int(AUTOMATION_TIME[0]), int(AUTOMATION_TIME[1])

for date_value in sorted([get_next_weekday(f'{datetime.now().date()}', day) for day in DAYS]):
    date_list = date_value.split('-')
    YEAR, MONTH, DAY = int(date_list[0]), int(date_list[1]), int(date_list[2])

    if datetime.now() < datetime(year=YEAR, month=MONTH, day=DAY, hour=HOUR, minute=MINUTE):
        later = datetime(year=YEAR, month=MONTH, day=DAY, hour=HOUR, minute=MINUTE)
        print(f"TokenRemover will run at {later}")
        print((later - datetime.now()).total_seconds())
        sys.exit(0)
