
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
  "dist_version" => "0.41",
  "license" => "perl",
  "module_name" => "Log::Any::App",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::HomeDir" => 0,
    "File::Path" => "2.07",
    "JSON" => 0,
    "Log::Any" => "0.14",
    "Log::Any::Adapter" => "0.07",
    "Log::Any::Adapter::Log4perl" => "0.06",
    "Log::Dispatch::Dir" => "0.10",
    "Log::Dispatch::FileRotate" => "1.19",
    "Log::Dispatch::Syslog" => "2.29",
    "Log::Log4perl" => "1.36",
    "perl" => "5.008000"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
