#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Any::App' );
}

diag( "Testing Log::Any::App $Log::Any::App::VERSION, Perl $], $^X" );
