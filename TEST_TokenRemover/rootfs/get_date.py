#!/usr/bin/env python3

# import needed modules
from datetime import timedelta, datetime
import sys

weekdays = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
}
def get_next_weekday(startdate, weekday):
    """
    @startdate: given date, in format '2013-05-25'
    @weekday: week day as a integer, between 0 (Monday) to 6 (Sunday)
    """
    d = datetime.strptime(startdate, '%Y-%m-%d')
    t = timedelta((7 + weekday - d.weekday()) % 7)
    return (d + t).strftime('%Y-%m-%d')

ds = sorted([get_next_weekday(f'{datetime.now().date()}', weekdays[day]) for day in days])

for d in ds:
    e = d.split('-')

    if datetime.now() < datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45):
        later = datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45)
        print(f'Next check is at {later}')
        print((later - datetime.now()).total_seconds())
        sys.exit(0)
        #pause.until(datetime(year=int(e[0]), month=int(e[1])+1, day=int(e[2]), hour=3, minute=45))

