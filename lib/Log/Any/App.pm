package Log::Any::App;
our $VERSION = '0.01';
# ABSTRACT: A simple wrapper for Log::Any + Log::Log4perl for use in applications


use strict;
use warnings;

use File::HomeDir;
use File::Path qw(make_path);
use File::Spec;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Log4perl;


my $init_args;
my $init_called;

sub init {
    return if $init_called++;

    my ($args, $caller) = @_;
    $caller ||= caller();

    my $spec = _parse_args($args, $caller);
    return unless $spec->{init};
    _init_log4perl($spec);
}

sub _init_log4perl {
    my ($spec) = @_;

    # create intermediate directories for dir
    for (@{ $spec->{dirs} }) {
        my $dir = _dirname($_->{path});
        make_path($dir) if length($dir) && !(-d $dir);
    }

    # create intermediate directories for file
    for (@{ $spec->{files} }) {
        my $dir = _dirname($_->{path});
        make_path($dir) if length($dir) && !(-d $dir);
    }

    my $config_appenders = '';
    my %cats = ('' => {appenders => [], level => $spec->{level}});
    my $i = 0;
    for (@{ $spec->{dirs} }) {
        my $cat = _format_category($_->{category});
        my $a = "DIR" . ($i++);
        $cats{$cat} ||= {appenders => [], level => $spec->{level}};
        push @{ $cats{$cat}{appenders} }, $a;
        $cats{$cat}{level} = _max_level($cats{$cat}{level}, $_->{level});
        $config_appenders .= join(
            "",
            "log4perl.appender.$a = Log::Dispatch::Dir\n",
            "log4perl.appender.$a.dirname = $_->{path}\n",
            "log4perl.appender.$a.filename_pattern = $_->{filename_pattern}\n",
            ($_->{max_size} ? "log4perl.appender.$a.max_size = $_->{max_size}\n" : ""),
            ($_->{histories} ? "log4perl.appender.$a.max_files = " . ($_->{histories}+1) . "\n" : ""),
            ($_->{max_age} ? "log4perl.appender.$a.max_age = $_->{max_age}\n" : ""),
            "log4perl.appender.$a.layout = PatternLayout\n",
            "log4perl.appender.$a.layout.ConversionPattern = $_->{pattern}\n",
            "\n",
        );
    }
    $i = 0;
    for (@{ $spec->{files} }) {
        my $cat = _format_category($_->{category});
        my $a = "FILE" . ($i++);
        $cats{$cat} ||= {appenders => [], level => $spec->{level}};
        push @{ $cats{$cat}{appenders} }, $a;
        $cats{$cat}{level} = _max_level($cats{$cat}{level}, $_->{level});
        $config_appenders .= join(
            "",
            "log4perl.appender.$a = Log::Dispatch::FileRotate\n",
            "log4perl.appender.$a.filename = $_->{path}\n",
            ($_->{max_size} ? "log4perl.appender.$a.size = " . ($_->{max_size}/1024/1024) . "\n" : ""),
            ($_->{histories} ? "log4perl.appender.$a.max = " . ($_->{histories}+1) . "\n" : ""),
            "log4perl.appender.$a.layout = PatternLayout\n",
            "log4perl.appender.$a.layout.ConversionPattern = $_->{pattern}\n",
            "\n",
        );
    }
    $i = 0;
    for (@{ $spec->{screens} }) {
        my $cat = _format_category($_->{category});
        my $a = "SCREEN" . ($i++);
        $cats{$cat} ||= {appenders => [], level => $spec->{level}};
        push @{ $cats{$cat}{appenders} }, $a;
        $cats{$cat}{level} = _max_level($cats{$cat}{level}, $_->{level});
        $config_appenders .= join(
            "",
            "log4perl.appender.$a = Log::Log4perl::Appender::ScreenColoredLevels\n",
            ("log4perl.appender.$a.stderr = " . ($_->{stderr} ? 1 : 0) . "\n"),
            "log4perl.appender.$a.layout = PatternLayout\n",
            "log4perl.appender.$a.layout.ConversionPattern = $_->{pattern}\n",
            "\n",
        );
    }
    $i = 0;
    for (@{ $spec->{syslogs} }) {
        my $cat = _format_category($_->{category});
        my $a = "SYSLOG" . ($i++);
        $cats{$cat} ||= {appenders => [], level => $spec->{level}};
        push @{ $cats{$cat}{appenders} }, $a;
        $cats{$cat}{level} = _max_level($cats{$cat}{level}, $_->{level});
        $config_appenders .= join(
            "",
            "log4perl.appender.$a = Log::Dispatch::Syslog\n",
            "log4perl.appender.$a.ident = $_->{ident}\n",
            "log4perl.appender.$a.facility = $_->{facility}\n",
            "log4perl.appender.$a.layout = PatternLayout\n",
            "log4perl.appender.$a.layout.ConversionPattern = $_->{pattern}\n",
            "\n",
        );
    }
    my $config_cats = '';
    for (sort {$a cmp $b} keys %cats) {
        my $c = $cats{$_};
        my $l = $_ eq '' ? "rootLogger" : "logger.$_";
        $config_cats .= "log4perl.$l = ".join(", ", uc($c->{level}), @{ $c->{appenders} })."\n";
    }
    my $config = $config_cats . "\n" . $config_appenders;

    #print $config; exit;
    Log::Log4perl->init(\$config);
    Log::Any::Adapter->set('Log4perl');
}

sub _basename {
    my $path = shift;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    $file;
}

sub _dirname {
    my $path = shift;
    my ($vol, $dir, $file) = File::Spec->splitpath($path);
    $dir;
}

sub _parse_args {
    my ($args, $caller) = @_;

    my $spec = {
        name => _basename($0),
        level => _find_level("") || "info",
        init => 1,
    };

    my $i = 0;
    while ($i < @$args) {
        my $arg = $args->[$i];
        if ($arg eq '$log') {
            _export_logger($caller);
        } elsif ($arg =~ /^-(\w+)$/) {
            my $opt = $1;
            die "Missing argument for option $arg" unless $i++ <= @$args-1;
            $arg = $args->[$i];
            if ($opt eq 'init') {
                $spec->{init} = $arg;
            } elsif ($opt eq 'name') {
                $spec->{name} = $arg;
            } elsif ($opt eq 'level') {
                $spec->{level} = _check_level($arg, "-level");
            } elsif ($opt eq 'file') {
                $spec->{files} = [];
                _parse_opt_file($spec, $arg);
            } elsif ($opt eq 'dir') {
                $spec->{dirs} = [];
                _parse_opt_dir($spec, $arg);
            } elsif ($opt eq 'screen') {
                $spec->{screens} = [];
                _parse_opt_screen($spec, $arg);
            } elsif ($opt eq 'syslog') {
                $spec->{syslogs} = [];
                _parse_opt_syslog($spec, $arg);
            } else {
                die "Unknown option $opt";
            }
        } else {
            die "Unknown argument $arg";
        }
        $i++;
    }

    if (!$spec->{files}) {
        #$spec->{files} = $0 eq '-e' ? [] : [_default_file($spec)];
    }
    if (!$spec->{dirs}) {
        $spec->{dirs} = [];
    }
    if (!$spec->{screens}) {
        $spec->{screens} = [_default_screen($spec)];
    }
    if (!$spec->{syslogs}) {
        $spec->{syslogs} = _is_daemon() ? [_default_syslog($spec)] : [];
    }

    #use Data::Dumper; print Dumper $spec;
    $spec;
}

sub _is_daemon {
    $INC{"App/Daemon.pm"} ||
    $INC{"Daemon/Easy.pm"} ||
    $INC{"Daemon/Daemonize.pm"} ||
    $INC{"Daemon/Generic.pm"} ||
    $INC{"Daemonise.pm"} ||
    $INC{"Daemon/Simple.pm"} ||
    $INC{"HTTP/Daemon.pm"} ||
    $INC{"IO/Socket/INET/Daemon.pm"} ||
    $INC{"Mojo/Server/Daemon.pm"} ||
    $INC{"MooseX/Daemonize.pm"} ||
    $INC{"Net/Daemon.pm"} ||
    $INC{"Net/Server.pm"} ||
    $INC{"Proc/Daemon.pm"} ||
    $INC{"Proc/PID/File.pm"} ||
    $INC{"Win32/Daemon/Simple.pm"} ||
    0;
}

sub _default_file {
    my ($spec) = @_;
    return {
        level => _find_level("file") || $spec->{level},
        path => $> ? File::Spec->catfile(File::HomeDir->my_home, "$spec->{name}.log") :
            "/var/log/$spec->{name}.log", # XXX and on Windows?
        max_size => undef,
        histories => undef,
        category => '',
        pattern => '[pid %P] [%d] %m%n',
    };
}

sub _parse_opt_file {
    my ($spec, $arg) = @_;
    return unless $arg;
    if (!ref($arg) || ref($arg) eq 'HASH') {
        push @{ $spec->{files} }, _default_file($spec);
        return if $arg =~ /^(1|yes|true)$/i;
        if (!ref($arg)) {
            $spec->{files}[-1]{path} = $arg;
            return;
        }
        for my $k (keys %$arg) {
            for ($spec->{files}[-1]) {
                exists($_->{$k}) or die "Invalid file argument: $k, please only specify one of: " . join(", ", sort keys %$_);
                $_->{$k} = $k eq 'level' ? _check_level($arg->{$k}, "-file") : $arg->{$k};
            }
        }
    } elsif (ref($arg) eq 'ARRAY') {
        _parse_opt_file($spec, $_) for @$arg;
    } else {
        die "Invalid argument for -file, must be a boolean or hashref or arrayref";
    }
}

sub _default_dir {
    my ($spec) = @_;
    return {
        level => _find_level("dir") || $spec->{level},
        path => $> ? File::Spec->catfile(File::HomeDir->my_home, "log", $spec->{name}) :
            "/var/log/$spec->{name}", # XXX and on Windows?
        max_size => undef,
        max_age => undef,
        histories => undef,
        category => '',
        pattern => '%m',
        filename_pattern => 'pid-%{pid}-%Y-%m-%d-%H%M%S.txt',
    };
}

sub _parse_opt_dir {
    my ($spec, $arg) = @_;
    return unless $arg;
    if (!ref($arg) || ref($arg) eq 'HASH') {
        push @{ $spec->{dirs} }, _default_dir($spec);
        return if $arg =~ /^(1|yes|true)$/i;
        if (!ref($arg)) {
            $spec->{dirs}[-1]{path} = $arg;
            return;
        }
        for my $k (keys %$arg) {
            for ($spec->{dirs}[-1]) {
                exists($_->{$k}) or die "Invalid dir argument: $k, please only specify one of: " . join(", ", sort keys %$_);
                $_->{$k} = $k eq 'level' ? _check_level($arg->{$k}, "-dir") : $arg->{$k};
            }
        }
    } elsif (ref($arg) eq 'ARRAY') {
        _parse_opt_dir($spec, $_) for @$arg;
    } else {
        die "Invalid argument for -dir, must be a boolean or hashref or arrayref";
    }
}

sub _default_screen {
    my ($spec) = @_;
    return {
        color => 1,
        stderr => 1,
        level => _find_level("screen") || $spec->{level},
        category => '',
        pattern => '[%r] %m%n',
    };
}

sub _parse_opt_screen {
    my ($spec, $arg) = @_;
    return unless $arg;
    push @{ $spec->{screens} }, _default_screen($spec);
    return if $arg =~ /^(1|yes|true)$/i;
    if (ref($arg) eq 'HASH') {
        for my $k (keys %$arg) {
            for ($spec->{screens}[0]) {
                exists($_->{$k}) or die "Invalid screen argument: $k, please only specify one of: " . join(", ", sort keys %$_);
                $_->{$k} = $k eq 'level' ? _check_level($arg->{$k}, "-screen") : $arg->{$k};
            }
        }
    } else {
        die "Invalid argument for -screen, must be a boolean or hashref";
    }
}

sub _default_syslog {
    my ($spec) = @_;
    return {
        level => _find_level("syslog") || $spec->{level},
        ident => $spec->{name},
        facility => 'daemon',
        pattern => '[pid %P] %m',
        category => '',
    };
}

sub _parse_opt_syslog {
    my ($spec, $arg) = @_;
    return unless $arg;
    push @{ $spec->{syslogs} }, _default_syslog($spec);
    return if $arg =~ /^(1|yes|true)$/i;
    if (ref($arg) eq 'HASH') {
        for my $k (keys %$arg) {
            for ($spec->{syslogs}[0]) {
                exists($_->{$k}) or die "Invalid syslog argument: $k, please only specify one of: " . join(", ", sort keys %$_);
                $_->{$k} = $k eq 'level' ? _check_level($arg->{$k}, "-syslog") : $arg->{$k};
            }
        }
    } else {
        die "Invalid argument for -syslog, must be a boolean or hashref";
    }
}

sub _format_category {
    my ($cat) = @_;
    $cat =~ s/::/./g;
    lc($cat);
}

sub _check_level {
    my ($level, $from) = @_;
    $level =~ /^(fatal|error|warn|info|debug|trace)$/i or die "Unknown level (from $from): $level";
    lc($1);
}

sub _find_level {
    my ($prefix) = @_;
    my $p_ = $prefix ? "${prefix}_" : "";
    my $P_ = $prefix ? uc("${prefix}_") : "";
    my $F_ = $prefix ? ucfirst("${prefix}_") : "";
    my $pd = $prefix ? "${prefix}-" : "";
    my $pr = $prefix ? qr/$prefix(_|-)/ : qr//;
    my $key;

    if ($INC{"App/Options.pm"}) {
        return _check_level($App::options{$key}, "\$App::options{$key}") if $App::options{$key = $p_ . "log_level"};
        return _check_level($App::options{$key}, "\$App::options{$key}") if $App::options{$key = $p_ . "loglevel"};
        return "trace" if $App::options{$p_ . "trace"};
        return "debug" if $App::options{$p_ . "debug"};
        return "info" if $App::options{$p_ . "verbose"};
        return "error" if $App::options{$p_ . "quiet"};
    }

    my $i = 0;
    while ($i < @ARGV) {
        my $arg = $ARGV[$i];
        return _check_level($1, "ARGV $arg") if $arg =~ /^--${pr}log[_-]?level=(.+)/;
        return _check_level($ARGV[$i+1], "ARGV $ARGV[$i] ".$ARGV[$i+1]) if $arg =~ /^--${pr}log[_-]?level$/ and $i < @ARGV-1;
        return "trace"  if $arg =~ /^--${pr}trace(=(1|yes|true))?$/i;
        return "debug"  if $arg =~ /^--${pr}debug(=(1|yes|true))?$/i;
        return "info"   if $arg =~ /^--${pr}verbose(=(1|yes|true))?$/i;
        return "error"  if $arg =~ /^--${pr}quiet(=(1|yes|true))?$/i;
        $i++;
    }

    return _check_level($ENV{$key}, "ENV $key") if $ENV{$key = $P_ . "LOG_LEVEL"};
    return _check_level($ENV{$key}, "ENV $key") if $ENV{$key = $P_ . "LOGLEVEL"};
    return "trace" if $ENV{$P_ . "TRACE"};
    return "debug" if $ENV{$P_ . "DEBUG"};
    return "info"  if $ENV{$P_ . "VERBOSE"};
    return "error" if $ENV{$P_ . "QUIET"};

    no strict 'refs';
    return _check_level($$key, "\$$key") if (($key = "main::${F_}Log_Level") && $$key);
    return _check_level($$key, "\$$key") if (($key = "main::${P_}LOG_LEVEL") && $$key);
    return _check_level($$key, "\$$key") if (($key = "main::${p_}log_level") && $$key);
    return _check_level($$key, "\$$key") if (($key = "main::${F_}LogLevel") && $$key);
    return _check_level($$key, "\$$key") if (($key = "main::${P_}LOGLEVEL") && $$key);
    return _check_level($$key, "\$$key") if (($key = "main::${p_}loglevel") && $$key);
    return "trace" if (($key = "main::$F_" . "Trace"  ) && $$key || ($key = "main::$P_" . "TRACE"  ) && $$key || ($key = "main::$p_" . "trace"  ) && $$key);
    return "debug" if (($key = "main::$F_" . "Debug"  ) && $$key || ($key = "main::$P_" . "DEBUG"  ) && $$key || ($key = "main::$p_" . "debug"  ) && $$key);
    return "info"  if (($key = "main::$F_" . "Verbose") && $$key || ($key = "main::$P_" . "VERBOSE") && $$key || ($key = "main::$p_" . "verbose") && $$key);
    return "error" if (($key = "main::$F_" . "Quiet"  ) && $$key || ($key = "main::$P_" . "QUIET"  ) && $$key || ($key = "main::$p_" . "quiet"  ) && $$key);

    return;
}

# return the higher level (e.g. _max_level("debug", "INFO") -> INFO
sub _max_level {
    my ($l1, $l2) = @_;
    my %vals = (FATAL=>1, ERROR=>2, WARN=>3, INFO=>4, DEBUG=>5, TRACE=>6);
    $vals{uc($l1)} > $vals{uc($l2)} ? $l1 : $l2;
}

sub _export_logger {
    my ($caller) = @_;
    no strict 'refs';
    my $varname = "$caller\::log";
    *$varname = \$log;
}

sub import {
    my ($self, @args) = @_;
    $init_args = \@args;
}

CHECK {
    my $caller = caller();
    init($init_args, $caller);
}



1;

__END__
=pod

=head1 NAME

Log::Any::App - A simple wrapper for Log::Any + Log::Log4perl for use in applications

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    # in your script/application
    use Log::Any::App qw($log);

    # or, in command line
    % perl -MLog::Any::App -MModuleThatUsesLogAny -e ...

=head1 DESCRIPTION

L<Log::Any> makes life easy for module authors. All you need to do is:

 use Log::Any qw($log);

and you're off logging with $log->debug(), $log->info(),
$log->error(), etc. That's it. The task of initializing and
configuring the logger rests on the shoulder of module users.

It's less straightforward for module users though, especially for
casual ones. You have to pick an adapter and connect it to another
logging framework (like L<Log::Log4perl>) and configure it. The
typical incantation is like this:

 use Log::Any qw($log);
 use Log::Any::Adapter;
 use Log::Log4perl;
 my $log4perl_config = '
   some
   long
   multiline
   config...';
 Log::Log4perl->init(\$log4perl_config);
 Log::Any::Adapter->set('Log4perl');

Frankly, I couldn't possibly remember all that (especially the details
of Log4perl configuration), hence Log::Any::App. The goal of
Log::Any::App is to make life equally easy for application authors and
module users. All you need to do is:

 use Log::Any::App qw($log);

or, from the command line:

 perl -MLog::Any::App='$log' -MModuleThatUsesLogAny -e ...

and you can display the logs in screen, file(s), syslog, etc. You can
also log using $log->debug(), etc as usual. Most of the time you don't
need to configure anything as Log::Any::App will construct the most
appropriate default Log4perl config for your application.

I mostly use Log::Any;:App in scripts and one-liners whenever there
are Log::Any-using modules involved (like L<Data::Schema> or
L<Config::Tree>).

=head1 USING

Most of the time you just need to do this from command line:

 % perl -MLog::Any::App -MModuleThatUsesLogAny -e ...

or from a script:

 use Log::Any::App qw($log);

this will send logs to screen as well as file (~/$NAME.log or
/var/log/$NAME.log if running as root). One-liners by default do not
log to file. $NAME will be taken from $0, but can be changed using:

 use Log::Any::App '$log', -name => 'myprog';

Default level is 'warn', but can be changed in several ways. From the
code:

 use Log::Any::App '$log', -level => 'debug';

or:

 use Log::Any::App '$log';
 BEGIN {
     $Log_Level = 'fatal'; # setting to fatal
     # $Debug = 1;         # another way, setting to debug
     # $Verbose = 1;       # another way, setting to info
     # $Quiet = 1;         # another way, setting to error
 }

or from environment variable:

 LOG_LEVEL=fatal yourprogram.pl;   # setting level to fatal
 DEBUG=1 yourprogram.pl;           # setting level to debug
 VERBOSE=1 yourprogram.pl;         # setting level to info
 QUIET=1 yourproogram.pl;          # setting level to error

or, from the command line options:

 yourprogram.pl --log-level debug
 yourprogram.pl --debug
 # and so on

If you want to add a second file with a different level and category:

 use Log::Any::App '$log', -file => ['first.log',
                                     {path=>'second.log', level=>'debug',
                                      category=>'Some::Category'}];

If you want to turn off screen logging:

 use Log::Any::App -screen => 0;

Logging to syslog is enabled by default if your script looks like a
daemon, e.g.:

 use Net::Daemon; # this indicate your program is a daemon
 use Log::Any::App; # syslog logging will be turned on by default

but if you don't want syslog logging:

 use Log::Any::App -syslog => 0;

For all the available options, see the init() function.

=head1 FUNCTIONS

=head2 init(\@args)

This is the actual function that implements the setup and
configuration of everything. You normally need not call this function
explicitly, it will be called once in a CHECK block. In fact, when you do:

 use Log::Any::App 'a', 'b', 'c';

it is actually passed as:

 init(['a', 'b', 'c']);

Arguments to init can be one or more of:

=over 4

=item '$log'

This will export the default logger to the caller's package. If you
want other category than the default:

=item -init => BOOL

Default is true. You can set this to false, and you can initialize
Log4perl yourself (but then there's not much point in using this
module, right?)

=item -name => STRING

Change the program name. Default is taken from $0.

=item -level => 'debug'|'warn'|...

Specify log level for all outputs, e.g. C<warn>, C<debug>, etc. Each
output can override this value. The default log level is determined as
follow:

If L<App::Options> is present, these keys are checked in
B<%App::options>: B<log_level>, B<trace> (if true then level is
C<trace>), B<debug> (if true then level is C<debug>), B<verbose> (if
true then level is C<info>), B<quiet> (if true then level is
C<error>).

Otherwise, it will try to scrape @ARGV for the presence of
B<--log-level>, B<--trace>, B<--debug>, B<--verbose>, or B<--quiet>
(this usually works because Log::Any::App does this in the CHECK
phase, before you call L<Getopt::Long>'s GetOptions() or the like).

Otherwise, it will look for environment variables: B<LOG_LEVEL>,
B<TRACE>, B<DEBUG>, B<VERBOSE>, B<QUIET>.

Otherwise, it will try to search for package variables in the C<main>
namespace with names like C<$Log_Level> or C<$LOG_LEVEL> or
C<$log_level>, C<$Trace> or C<$TRACE> or C<$trace>, C<$Debug> or
C<$DEBUG> or C<$debug>, C<$Verbose> or C<$VERBOSE> or C<$verbose>,
C<$Quiet> or C<$QUIET> or C<$quiet>.

If everything fails, it defaults to 'warn'.

=item -file => 0 | 1|yes|true | PATH | {opts} | [{opts}, ...]

Specify output to one or more files, using
L<Log::Dispatch::FileRotate>.

If the argument is a false boolean value, file logging will be turned
off. If argument is a true value that matches /^(1|yes|true)$/i, file
logging will be turned on with default path, etc. If the argument is
another scalar value then it is assumed to be a path. If the argument
is a hashref, then the keys of the hashref must be one of: C<level>,
C<path>, C<max_size> (maximum size before rotating, in bytes, 0 means
unlimited or never rotate), C<histories> (number of old files to keep,
excluding the current file), C<category>, C<pattern> (Log4perl
pattern).

If the argument is an arrayref, it is assumed to be specifying
multiple files, with each element of the array as a hashref.

How Log::Any::App determines defaults for file logging:

If program is a one-liner script specified using "perl -e", the
default is no file logging. Otherwise file logging is turned on.

If the program runs as root, the default path is
C</var/log/$NAME.log>, where $NAME is taken from B<$0> (or
C<-name>). Otherwise the default path is ~/$NAME.log. Intermediate
directories will be made with L<File::Path>.

Default rotating behaviour is no rotate (max_size = 0).

Default level for file is the same as the global level set by
B<-level>. But App::options, command line, environment, and package
variables in main are also searched first (for B<FILE_LOG_LEVEL>,
B<FILE_TRACE>, B<FILE_DEBUG>, B<FILE_VERBOSE>, B<FILE_QUIET>, and the
similars).

=item -dir => 0 | 1|yes|true | PATH | {opts} | [{opts}, ...]

Log messages using L<Log::Dispatch::Dir>. Each message is logged into
separate files in the directory. Useful for dumping content
(e.g. HTML, network dumps, or temporary results).

If the argument is a false boolean value, dir logging will be turned
off. If argument is a true value that matches /^(1|yes|true)$/i, dir
logging will be turned on with defaults path, etc. If the argument is
another scalar value then it is assumed to be a directory path. If the
argument is a hashref, then the keys of the hashref must be one of:
C<level>, C<path>, C<max_size> (maximum total size of files before
deleting older files, in bytes, 0 means unlimited), C<max_age>
(maximum age of files to keep, in seconds, undef means
unlimited). C<histories> (number of old files to keep, excluding the
current file), C<category>, C<pattern> (Log4perl pattern),
C<filename_pattern> (pattern of file name).

If the argument is an arrayref, it is assumed to be specifying
multiple directories, with each element of the array as a hashref.

How Log::Any::App determines defaults for dir logging:

Directory logging is by default turned off. You have to explicitly
turn it on.

If the program runs as root, the default path is C</var/log/$NAME/>,
where $NAME is taken from B<$0>. Otherwise the default path is
~/log/$NAME/. Intermediate directories will be created with
File::Path. Program name can be changed using C<-name>.

Default rotating parameters are: histories=1000, max_size=0,
max_age=undef.

Default level for dir logging is the same as the global level set by
B<-level>. But App::options, command line, environment, and package
variables in main are also searched first (for B<DIR_LOG_LEVEL>,
B<DIR_TRACE>, B<DIR_DEBUG>, B<DIR_VERBOSE>, B<DIR_QUIET>, and the
similars).

=item -screen => 0 | 1|yes|true | {opts}

Log messages using L<Log::Log4perl::Appender::ScreenColoredLevels>.

If the argument is a false boolean value, screen logging will be
turned off. If argument is a true value that matches
/^(1|yes|true)$/i, screen logging will be turned on with default
settings. If the argument is a hashref, then the keys of the hashref
must be one of: C<color> (default is true, set to 0 to turn off
color), C<stderr> (default is true, set to 0 to log to stdout
instead), C<level>, C<category>, C<pattern> (Log4perl string pattern).

How Log::Any::App determines defaults for screen logging:

Screen logging is turned on by default.

Default level for screen logging is the same as the global level set
by B<-level>. But App::options, command line, environment, and package
variables in main are also searched first (for B<SCREEN_LOG_LEVEL>,
B<SCREEN_TRACE>, B<SCREEN_DEBUG>, B<SCREEN_VERBOSE>, B<SCREEN_QUIET>,
and the similars).

=item -syslog => 0 | 1|yes|true | {opts}

Log messages using L<Log::Dispatch::Syslog>.

If the argument is a false boolean value, syslog logging will be
turned off. If argument is a true value that matches
/^(1|yes|true)$/i, syslog logging will be turned on with default
level, ident, etc. If the argument is a hashref, then the keys of the
hashref must be one of: C<level>, C<ident>, C<facility>, C<category>,
C<pattern> (Log4perl pattern).

How Log::Any::App determines defaults for syslog logging:

If a program is a daemon (determined by detecting modules like
L<Net::Server> or L<Proc::PID::File>) then syslog logging is turned on
by default and facility is set to C<daemon>, otherwise the default is
off.

Ident is program's name by default ($0, or C<-name>).

Default level for syslog logging is the same as the global level set
by B<-level>. But App::options, command line, environment, and package
variables in main are also searched first (for B<SYSLOG_LOG_LEVEL>,
B<SYSLOG_TRACE>, B<SYSLOG_DEBUG>, B<SYSLOG_VERBOSE>, B<SYSLOG_QUIET>,
and the similars).

=back

=head1 FAQ

=head2 What's the benefit of using Log::Any::App?

All of Log::Any and all of Log::Log4perl, as what Log::Any::App does
is just combine those two (and add a thin wrapper). You still produce
log with Log::Any so later should portions of your application code
get refactored into modules, you don't need to change the logging
part.

=head2 Do I need Log::Any::App if I am writing modules?

No, if you write modules just use Log::Any.

=head2 Why Log4perl instead of Log::Dispatch?

You can use Log::Dispatch::* output modules in Log4perl but
(currently) not vice versa.

You can configure Log4perl using a configuration file, so you can
conveniently store your settings separate from the application.

Feel free to fork Log::Any::App and use Log::Dispatch instead if you
don't like Log4perl.

=head2 Why not just use Log4perl then? Why bother with Log::Any at all? You're tied to Log4perl anyway.

Yes, combining Log::Any with Log4perl (or some other adapter) is
necessary to get output, but that's only in applications. Your
Log::Any-using modules are still not tied to any adapter.

The goal is to keep using Log::Any in your modules, and have a
convenient way of displaying your logs in your applications, without a
long incantation.

Users of your modules can still use Log::Dispatch or some other
adapter if they want to. You are not forcing your module users to use
Log4perl.

Btw, I'm actually fine with a Log4perl-only world. It's just that
(currently) you need to explicitly initialize Log4perl so this might
irritate my users if I use Log4perl in my modules. Log::Any's default
is the nice 'null' logging so my users don't need to be aware of
logging at all.

=head2 How do I create extra logger objects?

The usual way as with Log::Any:

 my $other_log = Log::Any->get_logger(category => $category);

=head1 BUGS/TODOS

Need to provide appropriate defaults for Windows/other OS.

=head1 SEE ALSO

L<Log::Any>

L<Log::Log4perl>

=head1 AUTHOR

  Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

