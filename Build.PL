
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Log::Any::App',
  license       => 'perl',
  dist_abstract => "A\ simple\ wrapper\ for\ Log\:\:Any\ \+\ Log\:\:Log4perl\ for\ use\ in\ applications",
  dist_name     => "Log\-Any\-App",
  dist_author   => [
"Steven\ Haryanto\ \<stevenharyanto\@gmail\.com\>",
  ],
  requires      => {
    "File::HomeDir" => '0',
    "File::Spec" => '0',
    "Log::Any" => '0',
    "Log::Any::Adapter" => '0',
    "Test::More" => '0',
    "Log::Dispatch::Dir" => '0',
    "Log::Dispatch::Syslog" => '0',
    "File::Path" => '0',
    "Log::Dispatch::FileRotate" => '0',
    "Log::Log4perl" => '0',
    "Log::Any::Adapter::Log4perl" => '0',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
