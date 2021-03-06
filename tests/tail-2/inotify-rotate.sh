#!/bin/sh
# ensure that tail -F handles rotation

# Copyright (C) 2009-2014 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if test "$VERBOSE" = yes; then
  set -x
  tail --version
fi

. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
expensive_

# Wait several seconds for grep REGEXP FILE to succeed.
# Usage: grep_timeout REGEXP FILE
grep_timeout()
{
    local j
    for j in $(seq 150); do
        grep $1 $2 > /dev/null && return 0
        sleep 0.1
    done
    return 1
}

# For details, see
# http://lists.gnu.org/archive/html/bug-coreutils/2009-11/msg00213.html

# Perform at least this many iterations, because on multi-core systems
# the offending sequence of events can be surprisingly uncommon.
for i in $(seq 50); do
    echo $i
    rm -rf k x out
    # Normally less than a second is required here, but with heavy load
    # and a lot of disk activity, even 20 seconds is insufficient, which
    # leads to this timeout killing tail before the "ok" is written below.
    :>k && :>x || framework_failure_ failed to initialize files
    timeout 40 tail -F k > out 2>&1 &
    pid=$!
    sleep .1
    echo b > k;
    # wait for b to appear in out
    grep_timeout b out || fail_ failed to find b in out
    while :; do grep b out > /dev/null && break; done
    mv x k
    # wait for tail to detect the rename
    grep_timeout tail: out || { cat out; fail_ failed to detect rename; }
    echo ok >> k
    found=0
    # wait up to 10 seconds for "ok" to appear in out
    grep_timeout ok out && found=1
    kill $pid
    test $found = 0 && { cat out; fail_ failed to detect echoed '"ok"'; }
done

wait
Exit $fail
