
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'A simple wrapper for Log::Any + Log::Log4perl for use in applications',
                       'dist_author' => [
                                          'Steven Haryanto <stevenharyanto@gmail.com>'
                                        ],
                       'dist_name' => 'Log-Any-App',
                       'script_files' => [],
                       'module_name' => 'Log::Any::App',
                       'requires' => {
                                       'File::HomeDir' => '0',
                                       'File::Spec' => '0',
                                       'Log::Any' => '0',
                                       'Log::Any::Adapter' => '0',
                                       'Test::More' => '0',
                                       'Log::Dispatch::Dir' => '0',
                                       'Log::Dispatch::Syslog' => '0',
                                       'File::Path' => '2.07',
                                       'Log::Dispatch::FileRotate' => '0',
                                       'Log::Log4perl' => '0',
                                       'Log::Any::Adapter::Log4perl' => '0'
                                     },
                       'dist_version' => '0.03',
                       'license' => 'perl'
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
