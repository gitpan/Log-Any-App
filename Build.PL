
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Slurp' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'An easy way to use Log::Any in applications',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Log-Any-App',
  'dist_version' => '0.20',
  'license' => 'perl',
  'module_name' => 'Log::Any::App',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Dumper' => '0',
    'File::HomeDir' => '0',
    'File::Path' => '0',
    'File::Slurp' => '0',
    'File::Spec' => '0',
    'Log::Any' => '0.11',
    'Log::Any::Adapter' => '0',
    'Log::Any::Adapter::Log4perl' => '0',
    'Log::Dispatch::FileRotate' => '0',
    'Log::Dispatch::Syslog' => '0',
    'Log::Log4perl' => '0',
    'perl' => '5.010000',
    'vars' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
