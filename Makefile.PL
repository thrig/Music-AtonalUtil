#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Music::AtonalUtil',
  VERSION_FROM => 'lib/Music/AtonalUtil.pm',
  PREREQ_PM    => {
    'Algorithm::Permute' => 0,
    Carp                 => 0,
    'List::MoreUtils'    => 0,
    'Scalar::Util'       => 0,
    'Test::More'         => 0,
  },
  ( $] >= 5.005
    ? (
      ABSTRACT_FROM =>
        'lib/Music/AtonalUtil.pm',    # retrieve abstract from module
      AUTHOR => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'perl';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'http://github.com/thrig/Music-AtonalUtil',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Music-AtonalUtil'
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.010000;
}

WriteMakefile(%params);
