use strict;
use warnings;

use Test::More tests => 1;

diag "release testing: " . ($ENV{RELEASE_TESTING} ? 1 : 0);
ok(1);

