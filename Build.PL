
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Slurp" => 0,
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "An easy way to use Log::Any in applications",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Log-Any-App",
  "dist_version" => "0.38",
  "license" => "perl",
  "module_name" => "Log::Any::App",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Path" => "2.07",
    "JSON" => 0,
    "Log::Any::Adapter::Log4perl" => 0,
    "Log::Dispatch::Dir" => "0.08",
    "Log::Dispatch::FileRotate" => 0,
    "Log::Dispatch::Syslog" => 0,
    "perl" => "5.008000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
