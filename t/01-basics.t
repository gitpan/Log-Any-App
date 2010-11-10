#!perl -T

# check defaults

# XXX use Test::Deep?

use lib './t'; require 'testlib.pl';
use strict;
use warnings;

use Log::Any::App -dir => 0, -file => 0, -screen => 0, -syslog => 0, -init => 0;
use Test::More tests => 59;

test_init(
    name => 'default',
    num_dirs => 0, num_files => 1, num_screens => 1, num_syslogs => 0,
    level => 'warn',
    file_level => 'warn', screen_level => 'warn',
); #=7

{
    local $0 = "-e";
    test_init(
        name => '-e doesnt get file by default',
        num_dirs => 0, num_files => 0, num_screens => 1, num_syslogs => 0,
    ); #=4
}

my %vars;

%vars = (
    loglevel  => ["fatal", "fatal"],
    log_level => ["error", "error"],
    LogLevel  => ["debug", "debug"],
    Log_Level => ["info", "info"],
    LOGLEVEL  => ["trace", "trace"],
    LOG_LEVEL => ["TRACE", "trace"],
    Verbose   => [1, "info"],
    QUIET     => [1, "error"],
    Debug     => [1, "debug"],
    TRACE     => [1, "trace"],
); #10
while (my ($k, $v) = each %vars) {
    no strict 'refs';
    test_init(
        pre   => sub { $k = "main::$k"; $$k = $v->[0]; },
        name  => "setting general level via variable: \$$k = $v->[0]",
        level => $v->[1],
    ); #1
} #=10x1

%vars = (
    screen_loglevel  => ["fatal", screen => "fatal"],
    file_log_level   => ["error", file   => "error"],
    Screen_LogLevel  => ["debug", screen => "debug"],
    File_Log_Level   => ["INFO",  file   => "info" ],
    SCREEN_LOGLEVEL  => ["trace", screen => "trace"],
    FILE_LOG_LEVEL   => ["trace", file   => "trace"],
    Screen_Verbose   => [1,       screen => "info" ],
    FILE_QUIET       => [1,       file   => "error"],
    Screen_Debug     => [1,       screen => "debug"],
    FILE_TRACE       => [1,       file   => "trace"],
); #10
while (my ($k, $v) = each %vars) {
    no strict 'refs';
    test_init(
        pre   => sub { $k = "main::$k"; $$k = $v->[0]; },
        name  => "setting output level via variable: \$$k = $v->[0]",
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=10x2

%vars = (
    LOG_LEVEL => ["trace", "trace"],
    VERBOSE   => [1,       "info" ],
); #2
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { $ENV{$k} = $v->[0] },
        name  => "setting general level env: $k = $v->[0]",
        level => $v->[1],
    ); #1
} #=2x1

%vars = (
    SCREEN_LOG_LEVEL => ["trace", screen => "trace"],
    FILE_DEBUG       => [1,       file   => "debug"],
); #2
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { $ENV{$k} = $v->[0] },
        name  => "setting output level env: $k = $v->[0]",
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=2x2

%vars = (
    '--loglevel'   => ["fatal", "fatal"],
    '--log-level'  => ["DEBUG", "debug"],
    '--log_level'  => ["info" , "info" ],
    '--quiet'      => [undef  , "error"],
); #4
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { push @ARGV, grep {defined} $k, $v->[0] },
        name  => "setting general level via cmdline opts: ".join(" ", @ARGV),
        level => $v->[1],
    ); #1
} #=4x1

%vars = (
    '--screen-loglevel'   => ["fatal", screen => "fatal"],
    '--file_log-level'    => ["debug", file   => "debug"],
    '--screen-log_level'  => ["INFO" , screen => "info" ],
    '--file_quiet'        => [undef  , file   => "error"],
); #4
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { push @ARGV, grep {defined} $k, $v->[0] },
        name  => "setting output level via cmdline opts: ".join(" ", @ARGV),
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=4x2

# XXX priority/overrides (setting via env vs cmdline vs vars vs init args)
# XXX invalid level dies
# XXX syslog & dir: setting level
# XXX syslog: daemon automatically gets syslog
# XXX file: default path
# XXX dir: default path
# XXX screen: default color
# XXX and many more :)

# XXX setting general level via app::options
# XXX setting output level via app::options

