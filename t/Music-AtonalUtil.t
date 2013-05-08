#!perl

use strict;
use warnings;

use Test::More tests => 61;

eval 'use Test::Differences';    # display convenience
my $deeply = $@ ? \&is_deeply : \&eq_or_diff;

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

is_deeply( [ 0, 1, 2, 5, 6, 9 ], $atu->forte2pcs('6-Z44'), 'Forte to PCS1' );
is_deeply( [ 0, 1, 2, 5, 6, 9 ], $atu->forte2pcs('6-z44'), 'Forte to PCS2' );

is_deeply(
  scalar $atu->interval_class_content( [ 0, 2, 4 ] ),
  [ 0, 2, 0, 1, 0, 0 ],
  'icc icv'
);

is_deeply(
  scalar $atu->interval_class_content(
    [qw/9 0 2 4 6 4 2 11 7 9 11 0 9 8 9 11 8 4/]
  ),
  [qw/4 6 5 5 6 2/],
  'icc icv of non-unique pitch set'
);

$deeply->(
  $atu->intervals2pcs( 0, [qw/4 3 -1 1 5/] ),
  [qw/0 4 7 6 7 0/], 'intervals2pcs'
);

$deeply->(
  $atu->intervals2pcs( 2, [qw/7 -4 -3/] ),
  [qw/2 9 5 2/], 'intervals2pcs custom start'
);

is_deeply(
  $atu->invariance_matrix( [ 3, 5, 6, 9 ] ),
  [ [ 6, 8, 9, 0 ], [ 8, 10, 11, 2 ], [ 9, 11, 0, 3 ], [ 0, 2, 3, 6 ] ],
  'invariance matrix'
);

is_deeply( $atu->invert( 0, [ 0, 4, 7 ] ), [ 0, 8, 5 ], 'invert something' );

is_deeply(
  $atu->multiply( 5, [ 10, 9, 0, 11 ] ),
  [ 2, 9, 0, 7 ],
  'multiply something'
);

is_deeply(
  ( $atu->normal_form( [ 6, 6, 7, 2, 2, 1, 3, 3, 3 ] ) )[0],
  [ 1, 2, 3, 6, 7 ],
  'normal form'
);

is_deeply(
  ( $atu->normal_form( [ 1, 4, 7, 8, 10 ] ) )[0],
  [ 7, 8, 10, 1, 4 ],
  'normal form compactness'
);

is_deeply(
  ( $atu->normal_form( [ 8, 10, 2, 4 ] ) )[0],
  [ 2, 4, 8, 10 ],
  'normal form lowest number fallthrough'
);

is_deeply(
  ( $atu->normal_form(
      [ map { my $s = $_ + 24; $s } 6, 6, 7, 2, 2, 1, 3, 3, 3 ]
    )
  )[0],
  [ 1, 2, 3, 6, 7 ],
  'normal form non-base-register pitches'
);

is_deeply(
  [ $atu->normal_form( 0, 4, 7, 12 ) ],
  [ [ 0, 4, 7 ], { 0 => [ 0, 12 ], 4 => [4], 7 => [7] } ],
  'normal form <c e g c>'
);

is( $atu->pcs2forte( [ 0, 1, 3, 4, 7, 8 ] ), '6-z19', 'PCS to Forte 1' );
is( $atu->pcs2forte( [qw/6 5 4 1 0 9/] ), '6-z44', 'PCS to Forte 2' );

is( $atu->pcs2forte( [ 0,  7,  4 ] ),  '3-11', 'PCS to Forte redux 1' );
is( $atu->pcs2forte( [ 4,  1,  8 ] ),  '3-11', 'PCS to Forte redux 2' );
is( $atu->pcs2forte( [ 12, 19, 16 ] ), '3-11', 'PCS to Forte redux 3' );

$deeply->( $atu->pcs2intervals( [qw/0 1 3/] ), [qw/1 2/], 'pcs2intervals' );

is( $atu->pitch2intervalclass(0),  0, 'pitch2intervalclass 0' );
is( $atu->pitch2intervalclass(1),  1, 'pitch2intervalclass 1' );
is( $atu->pitch2intervalclass(11), 1, 'pitch2intervalclass 11' );
is( $atu->pitch2intervalclass(6),  6, 'pitch2intervalclass 6' );

is_deeply(
  $atu->prime_form( [ 9, 10, 11, 2, 3 ] ),
  [ 0, 1, 2, 5, 6 ],
  'prime form'
);

is_deeply(
  $atu->prime_form( [ 21, 22, 23, 14, 15 ] ),
  [ 0, 1, 2, 5, 6 ],
  'prime form should normalize'
);

is_deeply( $atu->retrograde( [ 1, 2, 3 ] ), [ 3, 2, 1 ], 'retrograde' );

is_deeply( $atu->rotate( 0, [ 1, 2, 3 ] ), [ 1, 2, 3 ], 'rotate by 0' );

is_deeply( $atu->rotate( 1, [ 1, 2, 3 ] ), [ 3, 1, 2 ], 'rotate by 1' );

is_deeply( $atu->rotate( 2, [ 1, 2, 3 ] ), [ 2, 3, 1 ], 'rotate by 2' );

is_deeply( $atu->rotate( -1, [ 1, 2, 3 ] ), [ 2, 3, 1 ], 'rotate by -1' );

is_deeply( $atu->rotateto( 'c', 1, [qw/a b c d e c g/] ),
  [qw/c d e c g a b/], 'rotate to' );

is_deeply( $atu->rotateto( 'c', -1, [qw/a b c d e c g/] ),
  [qw/c g a b c d e/], 'rotate to the other way' );

# Verified against Musimathics, v.1, p.320.
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

# XXX do not know what order permutations will be generated with, and
# mostly just leaning on Algorithm::Permute, so skip 'subset' tests. :/

is_deeply(
  $atu->tcis( [ 10, 9, 0, 11 ] ),
  [ 1, 0, 0, 0, 0, 0, 1, 2, 3, 4, 3, 2 ],
  'transposition inversion common-tone structure (TICS)'
);

is_deeply(
  $atu->tcs( [ 0, 1, 2, 3 ] ),
  [ 4, 3, 2, 1, 0, 0, 0, 0, 0, 1, 2, 3 ],
  'transposition common-tone structure (TCS)'
);

is_deeply( $atu->transpose( 3, [ 11, 0, 1, 4, 5 ] ),
  [ 2, 3, 4, 7, 8 ], 'transpose' );

is_deeply(
  $atu->transpose_invert( 1, 0, [ 10, 9, 0, 11 ] ),
  [ 3, 4, 1, 2 ],
  'transpose_invert'
);

is_deeply(
  $atu->transpose_invert( 1, 6, [ 0, 11, 3 ] ),
  [ 7, 8, 4 ],
  'transpose_invert with axis'
);

is_deeply(
  scalar $atu->variances( [ 3, 5, 6, 9 ], [ 6, 8, 9, 0 ] ),
  [ 6, 9 ],
  'variances - scalar intersection'
);

ok( $atu->zrelation( [ 0, 1, 3, 7 ], [ 0, 1, 4, 6 ] ) == 1, 'z-related yes' );
ok( $atu->zrelation( [ 0, 1, 3 ], [ 0, 3, 7 ] ) == 0, 'z-related no' );

########################################################################
#
# nexti and company, plus other not-really-atonal routines

my @notes = qw/a b c f e/;
ok( $atu->geti( \@notes ) == 0,    'geti' );
ok( $atu->whati( \@notes ) eq 'a', 'whati' );
ok( $atu->nexti( \@notes ) eq 'b', 'nexti' );
$atu->seti( \@notes, 4 );
ok( $atu->nexti( \@notes ) eq 'a', 'nexti' );

is_deeply( [ $atu->lastn( [qw/a b c/] ) ], [qw/b c/], 'lastn default' );
is_deeply( [ $atu->lastn( [qw/a b c/], 99 ) ], [qw/a b c/],
  'lastn overflow' );
$atu = Music::AtonalUtil->new( lastn => 3 );
is_deeply( [ $atu->lastn( [qw/a b c/] ) ], [qw/a b c/], 'lastn custom n' );

{
  my @pitches  = -10 .. 10;
  my @expected = qw/2 3 4 5 4 3 2 3 4 5 4 3 2 3 4 5 4 3 2 3 4/;
  my @results;
  for my $p (@pitches) {
    push @results, $atu->reflect_pitch( $p, 2, 5 );
  }
  is_deeply( \@results, \@expected, 'reflect_pitch' );
}

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
