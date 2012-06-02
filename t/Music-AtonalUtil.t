use strict;
use warnings;

use Test::More tests => 33;

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
  $atu->multiply( [ 10, 9, 0, 11 ], 5 ),
  [ 2, 9, 0, 7 ],
  'multiply something'
);

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

is_deeply( $atu->retrograde( [ 1, 2, 3 ] ), [ 3, 2, 1 ], 'retrograde' );

is_deeply( $atu->rotate( [ 1, 2, 3 ], 0 ), [ 1, 2, 3 ], 'rotate by 0' );

is_deeply( $atu->rotate( [ 1, 2, 3 ], 1 ), [ 3, 1, 2 ], 'rotate by 1' );

is_deeply( $atu->rotate( [ 1, 2, 3 ], 2 ), [ 2, 3, 1 ], 'rotate by 2' );

is_deeply( $atu->rotate( [ 1, 2, 3 ], -1 ), [ 2, 3, 1 ], 'rotate by -1' );

is_deeply(
  $atu->set_complex( [ 0, 8, 10, 6, 7, 5, 9, 1, 3, 2, 11, 4 ] ),
  [ [ 0,  8,  10, 6,  7,  5,  9,  1,  3,  2,  11, 4 ],
    [ 4,  0,  2,  10, 11, 9,  1,  5,  7,  6,  3,  8 ],
    [ 2,  10, 0,  8,  9,  7,  11, 3,  5,  4,  1,  6 ],
    [ 6,  2,  4,  0,  1,  11, 3,  7,  9,  8,  5,  10 ],
    [ 5,  1,  3,  11, 0,  10, 2,  6,  8,  7,  4,  9 ],
    [ 7,  3,  5,  1,  2,  0,  4,  8,  10, 9,  6,  11 ],
    [ 3,  11, 1,  9,  10, 8,  0,  4,  6,  5,  2,  7 ],
    [ 11, 7,  9,  5,  6,  4,  8,  0,  2,  1,  10, 3 ],
    [ 9,  5,  7,  3,  4,  2,  6,  10, 0,  11, 8,  1 ],
    [ 10, 6,  8,  4,  5,  3,  7,  11, 1,  0,  9,  2 ],
    [ 1,  9,  11, 7,  8,  6,  10, 2,  4,  3,  0,  5 ],
    [ 8,  4,  6,  2,  3,  1,  5,  9,  11, 10, 7,  0 ]
  ],
  'genereate set complex'
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

# Custom constructor
my $stu = Music::AtonalUtil->new( DEG_IN_SCALE => 17 );
isa_ok( $stu, 'Music::AtonalUtil' );

is( $stu->scale_degrees, 17, 'custom number of scale degrees' );
