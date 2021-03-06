#!/bin/sh
# Verify that the credentials are changed correctly.

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


. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
print_ver_ chroot

require_root_

root=$(id -nu 0) || skip_ "Couldn't lookup root username"

# Verify that root credentials are kept.
test $(chroot / whoami) = "$root" || fail=1
test "$(groups)" = "$(chroot / groups)" || fail=1

# Verify that credentials are changed correctly.
whoami_after_chroot=$(
  chroot --userspec=$NON_ROOT_USERNAME:$NON_ROOT_GROUP / whoami
)
test "$whoami_after_chroot" != "$root" || fail=1

# Verify that there are no additional groups.
id_G_after_chroot=$(
  chroot --userspec=$NON_ROOT_USERNAME:$NON_ROOT_GROUP \
    --groups=$NON_ROOT_GROUP / id -G
)
test "$id_G_after_chroot" = $NON_ROOT_GROUP || fail=1

# Verify that when specifying only the user name we get the current
# primary group ID.
test "$(chroot --userspec=$NON_ROOT_USERNAME / id -g)" = "$(id -g)" \
    || fail=1

# Verify that when specifying only a group we get the current user ID
test "$(chroot --userspec=:$NON_ROOT_GROUP / id -u)" = "$(id -u)" \
    || fail=1

Exit $fail
