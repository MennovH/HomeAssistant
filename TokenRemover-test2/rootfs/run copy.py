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
    #print([day-1 for day in range(len([1,0,0,0,1,0,0])) if [1,0,0,0,1,0,0][day] == 'true'])
    print(weekdays)
    print(sys.argv[3], sys.argv[4].split(':'), weekdays)
    # elif sys.argv[1] == '1':
        # Run tokenremover       
        # result = tokenremover(sys.argv[2], sys.argv[3], sys.argv[4])
    # else:
        # result = addon("".join(sys.argv[2:])) #change to 3

    # print(result)
    # sys.exit(0)
    
