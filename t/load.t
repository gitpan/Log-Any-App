#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Any::App', -file => 0 );
}

diag( "Testing Log::Any::App $Log::Any::App::VERSION, Perl $], $^X" );
