use strict;
use warnings;

use Test::More tests => 24;

########################################################################
#
# Fundamentals

BEGIN { use_ok('Music::AtonalUtil') }

my $atu = Music::AtonalUtil->new;
isa_ok( $atu, 'Music::AtonalUtil' );

is( $atu->scale_degrees, 12, 'expect 12 degrees in scale by default' );

########################################################################
#
# Atonal Foo

is_deeply(
  $atu->circular_permute( [ 0, 1, 2 ] ),
  [ [ 0, 1, 2 ], [ 1, 2, 0 ], [ 2, 0, 1 ] ],
  'circular permutation'
);

is_deeply(
  $atu->complement( [ 0, 1, 2, 3, 4, 5 ] ),
  [ 6, 7, 8, 9, 10, 11 ],
  'pitch set complement'
);

is_deeply(
  scalar $atu->interval_class_content( [ 0, 2, 4 ] ),
  [ 0, 2, 0, 1, 0, 0 ],
  'icc icv'
);

is_deeply(
  $atu->invariance_matrix( [ 3, 5, 6, 9 ] ),
  [ [ 6, 8, 9, 0 ], [ 8, 10, 11, 2 ], [ 9, 11, 0, 3 ], [ 0, 2, 3, 6 ] ],
  'invariance matrix'
);

is_deeply( $atu->invert( [ 0, 4, 7 ] ), [ 0, 8, 5 ], 'invert something' );

is_deeply(
  $atu->normal_form( [ 6, 6, 7, 2, 2, 1, 3, 3, 3 ] ),
  [ 1, 2, 3, 6, 7 ],
  'normal form'
);

is_deeply(
  $atu->normal_form( [ 1, 4, 7, 8, 10 ] ),
  [ 7, 8, 10, 1, 4 ],
  'normal form compactness'
);

is_deeply(
  $atu->normal_form( [ 8, 10, 2, 4 ] ),
  [ 2, 4, 8, 10 ],
  'normal form lowest number fallthrough'
);

is( $atu->pitch2intervalclass(0),  0, 'pitch2intervalclass 0' );
is( $atu->pitch2intervalclass(1),  1, 'pitch2intervalclass 1' );
is( $atu->pitch2intervalclass(11), 1, 'pitch2intervalclass 11' );
is( $atu->pitch2intervalclass(6),  6, 'pitch2intervalclass 6' );

is_deeply(
  $atu->prime_form( [ 9, 10, 11, 2, 3 ] ),
  [ 0, 1, 2, 5, 6 ],
  'prime form'
);

is_deeply( $atu->transpose( [ 11, 0, 1, 4, 5 ], 3 ),
  [ 2, 3, 4, 7, 8 ], 'transpose' );

is_deeply(
  scalar $atu->variances( [ 3, 5, 6, 9 ], [ 6, 8, 9, 0 ] ),
  [ 6, 9 ],
  'variances - scalar intersection'
);

ok( $atu->zrelation( [ 0, 1, 3, 7 ], [ 0, 1, 4, 6 ] ) == 1, 'z-related yes' );
ok( $atu->zrelation( [ 0, 1, 3 ], [ 0, 3, 7 ] ) == 0, 'z-related no' );

########################################################################
#
# Other Tests

$atu->scale_degrees(3);
is( $atu->scale_degrees, 3, 'custom number of scale degrees' );

is( $atu->pitch2intervalclass(0), 0, 'pitch2intervalclass (dis3) 0' );
is( $atu->pitch2intervalclass(1), 1, 'pitch2intervalclass (dis3) 1' );
is( $atu->pitch2intervalclass(2), 1, 'pitch2intervalclass (dis3) 2' );
