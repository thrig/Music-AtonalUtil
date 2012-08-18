use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Music::AtonalUtil',
  VERSION_FROM => 'lib/Music/AtonalUtil.pm',
  LICENSE      => 'perl',
  PREREQ_PM    => {
    Algorithm::Permute => 0,
    Carp               => 0,
    List::MoreUtils    => 0,
    Test::More         => 0,
  },
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM =>
        'lib/Music/AtonalUtil.pm',    # retrieve abstract from module
      AUTHOR => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);
