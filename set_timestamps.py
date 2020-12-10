"""Use filenames in google takeout for photos to set file modification time.

Helps nextcloud figure out what's going on when you just copy a takeout
into your nextcloud data directory.
"""

import os
import re
import time
import datetime


def process_file(filename, directory):
    """Set file modification time to whatever is in filename."""
    match = re.match(r'IMG_(?P<year>[0-9]{4})(?P<month>[0-9]{2})(?P<day>[0-9]{2})_(?P<hour>[0-9]{2})(?P<minute>[0-9]{2})(?P<second>[0-9]{2})', filename)                                     
    if match:
        integer_match = {k: int(v) for k, v in match.groupdict().items()}
        file_date = datetime.datetime(**integer_match)
        mod_time = time.mktime(file_date.timetuple())
        os.utime(directory + '/' + filename, (mod_time, mod_time))
        return

    match = re.match(r'(?P<year>[0-9]{4})(?P<month>[0-9]{2})(?P<day>[0-9]{2})_[0-9]{4}', filename)                                                                                           
    if match:
        integer_match = {k: int(v) for k, v in match.groupdict().items()}
        file_date = datetime.datetime(**integer_match, second=0)
        mod_time = time.mktime(file_date.timetuple())
        os.utime(directory + '/' + filename, (mod_time, mod_time))
        return

    match = re.match(r'(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2}).jpg', filename)                                                                                              
    if match:
        integer_match = {k: int(v) for k, v in match.groupdict().items()}
        file_date = datetime.datetime(**integer_match, second=0, minute=0, hour=0)
        mod_time = time.mktime(file_date.timetuple())
        os.utime(directory + '/' + filename, (mod_time, mod_time))
        return

    match = re.match(r'(?P<year>[0-9]{4})-(?P<month>[0-9]{2})-(?P<day>[0-9]{2})', directory)
    if match:
        integer_match = {k: int(v) for k, v in match.groupdict().items()}
        file_date = datetime.datetime(**integer_match, second=0, minute=0, hour=0)
        mod_time = time.mktime(file_date.timetuple())
        os.utime(directory + '/' + filename, (mod_time, mod_time))
        return

def process_directory(directory):
    """Recursively process files/directories."""
    for file in os.listdir(directory):
        if os.path.isdir(file):
            process_directory(file)
        else:
            process_file(file, directory)


process_directory('.')

