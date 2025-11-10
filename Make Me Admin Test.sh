#!/bin/bash

#This script will make the current user as admin and will give the prvileages for permanent.


U=`who |grep console| awk '{print $1}'`

# give current logged user admin rights

/usr/sbin/dseditgroup -o edit -a $U -t user admin



