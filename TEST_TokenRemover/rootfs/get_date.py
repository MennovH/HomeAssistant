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


days = []
num = -1
for day in sys.argv[1:]:
    num+=1
    if day == "true":
        days.append(num)
        

ds = sorted([get_next_weekday(f'{datetime.now().date()}', day) for day in days])

for d in ds:
    e = d.split('-')

    if datetime.now() < datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45):
        later = datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45)
        print(datetime.now())
        print(f"Next check is at {later}")
        print((later - datetime.now()).total_seconds())
        sys.exit(0)
        #pause.until(datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45))

