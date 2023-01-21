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

ds = sorted([get_next_weekday(f'{datetime.now().date()}', day) for day in DAYS])

for d in ds:
    e = d.split('-')

    if datetime.now() < datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=int(AUTOMATION_TIME[0]), minute=int(AUTOMATION_TIME[1])):
        later = datetime(year=int(e[0]), month=int(e[1]), day=int(e[2]), hour=3, minute=45)
        print(f"Next check is at {later}")
        print((later - datetime.now()).total_seconds())
        sys.exit(0)

