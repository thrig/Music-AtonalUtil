# Code for atonal music analysis and composition (plus an assortment of
# other routines perhaps suitable for composition needs but not exactly
# atonal, and I do not want to create some Music::KitchenDrawer or
# whatever for them, and I'm totally making all this up as I go along).

package Music::AtonalUtil;

use 5.010;
use strict;
use warnings;

use Algorithm::Permute ();
use Carp qw/croak/;
use List::MoreUtils qw/firstidx uniq/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.60';

my $DEG_IN_SCALE = 12;

# via http://en.wikipedia.org/wiki/Forte_number
my $FORTE2PCS = {
  '3-1'   => [ 0, 1, 2 ],
  '3-10'  => [ 0, 3, 6 ],
  '3-11'  => [ 0, 3, 7 ],
  '3-12'  => [ 0, 4, 8 ],
  '3-2'   => [ 0, 1, 3 ],
  '3-3'   => [ 0, 1, 4 ],
  '3-4'   => [ 0, 1, 5 ],
  '3-5'   => [ 0, 1, 6 ],
  '3-6'   => [ 0, 2, 4 ],
  '3-7'   => [ 0, 2, 5 ],
  '3-8'   => [ 0, 2, 6 ],
  '3-9'   => [ 0, 2, 7 ],
  '4-1'   => [ 0, 1, 2, 3 ],
  '4-10'  => [ 0, 2, 3, 5 ],
  '4-11'  => [ 0, 1, 3, 5 ],
  '4-12'  => [ 0, 2, 3, 6 ],
  '4-13'  => [ 0, 1, 3, 6 ],
  '4-14'  => [ 0, 2, 3, 7 ],
  '4-16'  => [ 0, 1, 5, 7 ],
  '4-17'  => [ 0, 3, 4, 7 ],
  '4-18'  => [ 0, 1, 4, 7 ],
  '4-19'  => [ 0, 1, 4, 8 ],
  '4-2'   => [ 0, 1, 2, 4 ],
  '4-20'  => [ 0, 1, 5, 8 ],
  '4-21'  => [ 0, 2, 4, 6 ],
  '4-22'  => [ 0, 2, 4, 7 ],
  '4-23'  => [ 0, 2, 5, 7 ],
  '4-24'  => [ 0, 2, 4, 8 ],
  '4-25'  => [ 0, 2, 6, 8 ],
  '4-26'  => [ 0, 3, 5, 8 ],
  '4-27'  => [ 0, 2, 5, 8 ],
  '4-28'  => [ 0, 3, 6, 9 ],
  '4-3'   => [ 0, 1, 3, 4 ],
  '4-4'   => [ 0, 1, 2, 5 ],
  '4-5'   => [ 0, 1, 2, 6 ],
  '4-6'   => [ 0, 1, 2, 7 ],
  '4-7'   => [ 0, 1, 4, 5 ],
  '4-8'   => [ 0, 1, 5, 6 ],
  '4-9'   => [ 0, 1, 6, 7 ],
  '4-z15' => [ 0, 1, 4, 6 ],
  '4-z29' => [ 0, 1, 3, 7 ],
  '5-1'   => [ 0, 1, 2, 3, 4 ],
  '5-10'  => [ 0, 1, 3, 4, 6 ],
  '5-11'  => [ 0, 2, 3, 4, 7 ],
  '5-13'  => [ 0, 1, 2, 4, 8 ],
  '5-14'  => [ 0, 1, 2, 5, 7 ],
  '5-15'  => [ 0, 1, 2, 6, 8 ],
  '5-16'  => [ 0, 1, 3, 4, 7 ],
  '5-19'  => [ 0, 1, 3, 6, 7 ],
  '5-2'   => [ 0, 1, 2, 3, 5 ],
  '5-20'  => [ 0, 1, 5, 6, 8 ],
  '5-21'  => [ 0, 1, 4, 5, 8 ],
  '5-22'  => [ 0, 1, 4, 7, 8 ],
  '5-23'  => [ 0, 2, 3, 5, 7 ],
  '5-24'  => [ 0, 1, 3, 5, 7 ],
  '5-25'  => [ 0, 2, 3, 5, 8 ],
  '5-26'  => [ 0, 2, 4, 5, 8 ],
  '5-27'  => [ 0, 1, 3, 5, 8 ],
  '5-28'  => [ 0, 2, 3, 6, 8 ],
  '5-29'  => [ 0, 1, 3, 6, 8 ],
  '5-3'   => [ 0, 1, 2, 4, 5 ],
  '5-30'  => [ 0, 1, 4, 6, 8 ],
  '5-31'  => [ 0, 1, 3, 6, 9 ],
  '5-32'  => [ 0, 1, 4, 6, 9 ],
  '5-33'  => [ 0, 2, 4, 6, 8 ],
  '5-34'  => [ 0, 2, 4, 6, 9 ],
  '5-35'  => [ 0, 2, 4, 7, 9 ],
  '5-4'   => [ 0, 1, 2, 3, 6 ],
  '5-5'   => [ 0, 1, 2, 3, 7 ],
  '5-6'   => [ 0, 1, 2, 5, 6 ],
  '5-7'   => [ 0, 1, 2, 6, 7 ],
  '5-8'   => [ 0, 2, 3, 4, 6 ],
  '5-9'   => [ 0, 1, 2, 4, 6 ],
  '5-z12' => [ 0, 1, 3, 5, 6 ],
  '5-z17' => [ 0, 1, 3, 4, 8 ],
  '5-z18' => [ 0, 1, 4, 5, 7 ],
  '5-z36' => [ 0, 1, 2, 4, 7 ],
  '5-z37' => [ 0, 3, 4, 5, 8 ],
  '5-z38' => [ 0, 1, 2, 5, 8 ],
  '6-1'   => [ 0, 1, 2, 3, 4, 5 ],
  '6-14'  => [ 0, 1, 3, 4, 5, 8 ],
  '6-15'  => [ 0, 1, 2, 4, 5, 8 ],
  '6-16'  => [ 0, 1, 4, 5, 6, 8 ],
  '6-18'  => [ 0, 1, 2, 5, 7, 8 ],
  '6-2'   => [ 0, 1, 2, 3, 4, 6 ],
  '6-20'  => [ 0, 1, 4, 5, 8, 9 ],
  '6-21'  => [ 0, 2, 3, 4, 6, 8 ],
  '6-22'  => [ 0, 1, 2, 4, 6, 8 ],
  '6-27'  => [ 0, 1, 3, 4, 6, 9 ],
  '6-30'  => [ 0, 1, 3, 6, 7, 9 ],
  '6-31'  => [ 0, 1, 4, 5, 7, 9 ],
  '6-32'  => [ 0, 2, 4, 5, 7, 9 ],
  '6-33'  => [ 0, 2, 3, 5, 7, 9 ],
  '6-34'  => [ 0, 1, 3, 5, 7, 9 ],
  '6-35'  => [ 0, 2, 4, 6, 8, 10 ],
  '6-5'   => [ 0, 1, 2, 3, 6, 7 ],
  '6-7'   => [ 0, 1, 2, 6, 7, 8 ],
  '6-8'   => [ 0, 2, 3, 4, 5, 7 ],
  '6-9'   => [ 0, 1, 2, 3, 5, 7 ],
  '6-z10' => [ 0, 1, 3, 4, 5, 7 ],
  '6-z11' => [ 0, 1, 2, 4, 5, 7 ],
  '6-z12' => [ 0, 1, 2, 4, 6, 7 ],
  '6-z13' => [ 0, 1, 3, 4, 6, 7 ],
  '6-z17' => [ 0, 1, 2, 4, 7, 8 ],
  '6-z19' => [ 0, 1, 3, 4, 7, 8 ],
  '6-z23' => [ 0, 2, 3, 5, 6, 8 ],
  '6-z24' => [ 0, 1, 3, 4, 6, 8 ],
  '6-z25' => [ 0, 1, 3, 5, 6, 8 ],
  '6-z26' => [ 0, 1, 3, 5, 7, 8 ],
  '6-z28' => [ 0, 1, 3, 5, 6, 9 ],
  '6-z29' => [ 0, 2, 3, 6, 7, 9 ],
  '6-z3'  => [ 0, 1, 2, 3, 5, 6 ],
  '6-z36' => [ 0, 1, 2, 3, 4, 7 ],
  '6-z37' => [ 0, 1, 2, 3, 4, 8 ],
  '6-z38' => [ 0, 1, 2, 3, 7, 8 ],
  '6-z39' => [ 0, 2, 3, 4, 5, 8 ],
  '6-z4'  => [ 0, 1, 2, 4, 5, 6 ],
  '6-z40' => [ 0, 1, 2, 3, 5, 8 ],
  '6-z41' => [ 0, 1, 2, 3, 6, 8 ],
  '6-z42' => [ 0, 1, 2, 3, 6, 9 ],
  '6-z43' => [ 0, 1, 2, 5, 6, 8 ],
  '6-z44' => [ 0, 1, 2, 5, 6, 9 ],
  '6-z45' => [ 0, 2, 3, 4, 6, 9 ],
  '6-z46' => [ 0, 1, 2, 4, 6, 9 ],
  '6-z47' => [ 0, 1, 2, 4, 7, 9 ],
  '6-z48' => [ 0, 1, 2, 5, 7, 9 ],
  '6-z49' => [ 0, 1, 3, 4, 7, 9 ],
  '6-z50' => [ 0, 1, 4, 6, 7, 9 ],
  '6-z6'  => [ 0, 1, 2, 5, 6, 7 ],
  '7-1'   => [ 0, 1, 2, 3, 4, 5, 6 ],
  '7-10'  => [ 0, 1, 2, 3, 4, 6, 9 ],
  '7-11'  => [ 0, 1, 3, 4, 5, 6, 8 ],
  '7-13'  => [ 0, 1, 2, 4, 5, 6, 8 ],
  '7-14'  => [ 0, 1, 2, 3, 5, 7, 8 ],
  '7-15'  => [ 0, 1, 2, 4, 6, 7, 8 ],
  '7-16'  => [ 0, 1, 2, 3, 5, 6, 9 ],
  '7-19'  => [ 0, 1, 2, 3, 6, 7, 9 ],
  '7-2'   => [ 0, 1, 2, 3, 4, 5, 7 ],
  '7-20'  => [ 0, 1, 2, 5, 6, 7, 9 ],
  '7-21'  => [ 0, 1, 2, 4, 5, 8, 9 ],
  '7-22'  => [ 0, 1, 2, 5, 6, 8, 9 ],
  '7-23'  => [ 0, 2, 3, 4, 5, 7, 9 ],
  '7-24'  => [ 0, 1, 2, 3, 5, 7, 9 ],
  '7-25'  => [ 0, 2, 3, 4, 6, 7, 9 ],
  '7-26'  => [ 0, 1, 3, 4, 5, 7, 9 ],
  '7-27'  => [ 0, 1, 2, 4, 5, 7, 9 ],
  '7-28'  => [ 0, 1, 3, 5, 6, 7, 9 ],
  '7-29'  => [ 0, 1, 2, 4, 6, 7, 9 ],
  '7-3'   => [ 0, 1, 2, 3, 4, 5, 8 ],
  '7-30'  => [ 0, 1, 2, 4, 6, 8, 9 ],
  '7-31'  => [ 0, 1, 3, 4, 6, 7, 9 ],
  '7-32'  => [ 0, 1, 3, 4, 6, 8, 9 ],
  '7-33'  => [ 0, 1, 2, 4, 6, 8, 10 ],
  '7-34'  => [ 0, 1, 3, 4, 6, 8, 10 ],
  '7-35'  => [ 0, 1, 3, 5, 6, 8, 10 ],
  '7-4'   => [ 0, 1, 2, 3, 4, 6, 7 ],
  '7-5'   => [ 0, 1, 2, 3, 5, 6, 7 ],
  '7-6'   => [ 0, 1, 2, 3, 4, 7, 8 ],
  '7-7'   => [ 0, 1, 2, 3, 6, 7, 8 ],
  '7-8'   => [ 0, 2, 3, 4, 5, 6, 8 ],
  '7-9'   => [ 0, 1, 2, 3, 4, 6, 8 ],
  '7-z12' => [ 0, 1, 2, 3, 4, 7, 9 ],
  '7-z17' => [ 0, 1, 2, 4, 5, 6, 9 ],
  '7-z18' => [ 0, 1, 4, 5, 6, 7, 9 ],
  '7-z36' => [ 0, 1, 2, 3, 5, 6, 8 ],
  '7-z37' => [ 0, 1, 3, 4, 5, 7, 8 ],
  '7-z38' => [ 0, 1, 2, 4, 5, 7, 8 ],
  '8-1'   => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
  '8-10'  => [ 0, 2, 3, 4, 5, 6, 7, 9 ],
  '8-11'  => [ 0, 1, 2, 3, 4, 5, 7, 9 ],
  '8-12'  => [ 0, 1, 3, 4, 5, 6, 7, 9 ],
  '8-13'  => [ 0, 1, 2, 3, 4, 6, 7, 9 ],
  '8-14'  => [ 0, 1, 2, 4, 5, 6, 7, 9 ],
  '8-16'  => [ 0, 1, 2, 3, 5, 7, 8, 9 ],
  '8-17'  => [ 0, 1, 3, 4, 5, 6, 8, 9 ],
  '8-18'  => [ 0, 1, 2, 3, 5, 6, 8, 9 ],
  '8-19'  => [ 0, 1, 2, 4, 5, 6, 8, 9 ],
  '8-2'   => [ 0, 1, 2, 3, 4, 5, 6, 8 ],
  '8-20'  => [ 0, 1, 2, 4, 5, 7, 8, 9 ],
  '8-21'  => [ 0, 1, 2, 3, 4, 6, 8, 10 ],
  '8-22'  => [ 0, 1, 2, 3, 5, 6, 8, 10 ],
  '8-23'  => [ 0, 1, 2, 3, 5, 7, 8, 10 ],
  '8-24'  => [ 0, 1, 2, 4, 5, 6, 8, 10 ],
  '8-25'  => [ 0, 1, 2, 4, 6, 7, 8, 10 ],
  '8-26'  => [ 0, 1, 3, 4, 5, 7, 8, 10 ],
  '8-27'  => [ 0, 1, 2, 4, 5, 7, 8, 10 ],
  '8-28'  => [ 0, 1, 3, 4, 6, 7, 9, 10 ],
  '8-3'   => [ 0, 1, 2, 3, 4, 5, 6, 9 ],
  '8-4'   => [ 0, 1, 2, 3, 4, 5, 7, 8 ],
  '8-5'   => [ 0, 1, 2, 3, 4, 6, 7, 8 ],
  '8-6'   => [ 0, 1, 2, 3, 5, 6, 7, 8 ],
  '8-7'   => [ 0, 1, 2, 3, 4, 5, 8, 9 ],
  '8-8'   => [ 0, 1, 2, 3, 4, 7, 8, 9 ],
  '8-9'   => [ 0, 1, 2, 3, 6, 7, 8, 9 ],
  '8-z15' => [ 0, 1, 2, 3, 4, 6, 8, 9 ],
  '8-z29' => [ 0, 1, 2, 3, 5, 6, 7, 9 ],
  '9-1'   => [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ],
  '9-10'  => [ 0, 1, 2, 3, 4, 6, 7, 9, 10 ],
  '9-11'  => [ 0, 1, 2, 3, 5, 6, 7, 9, 10 ],
  '9-12'  => [ 0, 1, 2, 4, 5, 6, 8, 9, 10 ],
  '9-2'   => [ 0, 1, 2, 3, 4, 5, 6, 7, 9 ],
  '9-3'   => [ 0, 1, 2, 3, 4, 5, 6, 8, 9 ],
  '9-4'   => [ 0, 1, 2, 3, 4, 5, 7, 8, 9 ],
  '9-5'   => [ 0, 1, 2, 3, 4, 6, 7, 8, 9 ],
  '9-6'   => [ 0, 1, 2, 3, 4, 5, 6, 8, 10 ],
  '9-7'   => [ 0, 1, 2, 3, 4, 5, 7, 8, 10 ],
  '9-8'   => [ 0, 1, 2, 3, 4, 6, 7, 8, 10 ],
  '9-9'   => [ 0, 1, 2, 3, 5, 6, 7, 8, 10 ],
};

my $PCS2FORTE = {
  '0,1,2'              => '3-1',
  '0,1,2,3'            => '4-1',
  '0,1,2,3,4'          => '5-1',
  '0,1,2,3,4,5'        => '6-1',
  '0,1,2,3,4,5,6'      => '7-1',
  '0,1,2,3,4,5,6,7'    => '8-1',
  '0,1,2,3,4,5,6,7,8'  => '9-1',
  '0,1,2,3,4,5,6,7,9'  => '9-2',
  '0,1,2,3,4,5,6,8'    => '8-2',
  '0,1,2,3,4,5,6,8,10' => '9-6',
  '0,1,2,3,4,5,6,8,9'  => '9-3',
  '0,1,2,3,4,5,6,9'    => '8-3',
  '0,1,2,3,4,5,7'      => '7-2',
  '0,1,2,3,4,5,7,8'    => '8-4',
  '0,1,2,3,4,5,7,8,10' => '9-7',
  '0,1,2,3,4,5,7,8,9'  => '9-4',
  '0,1,2,3,4,5,7,9'    => '8-11',
  '0,1,2,3,4,5,8'      => '7-3',
  '0,1,2,3,4,5,8,9'    => '8-7',
  '0,1,2,3,4,6'        => '6-2',
  '0,1,2,3,4,6,7'      => '7-4',
  '0,1,2,3,4,6,7,8'    => '8-5',
  '0,1,2,3,4,6,7,8,10' => '9-8',
  '0,1,2,3,4,6,7,8,9'  => '9-5',
  '0,1,2,3,4,6,7,9'    => '8-13',
  '0,1,2,3,4,6,7,9,10' => '9-10',
  '0,1,2,3,4,6,8'      => '7-9',
  '0,1,2,3,4,6,8,10'   => '8-21',
  '0,1,2,3,4,6,8,9'    => '8-z15',
  '0,1,2,3,4,6,9'      => '7-10',
  '0,1,2,3,4,7'        => '6-z36',
  '0,1,2,3,4,7,8'      => '7-6',
  '0,1,2,3,4,7,8,9'    => '8-8',
  '0,1,2,3,4,7,9'      => '7-z12',
  '0,1,2,3,4,8'        => '6-z37',
  '0,1,2,3,5'          => '5-2',
  '0,1,2,3,5,6'        => '6-z3',
  '0,1,2,3,5,6,7'      => '7-5',
  '0,1,2,3,5,6,7,8'    => '8-6',
  '0,1,2,3,5,6,7,8,10' => '9-9',
  '0,1,2,3,5,6,7,9'    => '8-z29',
  '0,1,2,3,5,6,7,9,10' => '9-11',
  '0,1,2,3,5,6,8'      => '7-z36',
  '0,1,2,3,5,6,8,10'   => '8-22',
  '0,1,2,3,5,6,8,9'    => '8-18',
  '0,1,2,3,5,6,9'      => '7-16',
  '0,1,2,3,5,7'        => '6-9',
  '0,1,2,3,5,7,8'      => '7-14',
  '0,1,2,3,5,7,8,10'   => '8-23',
  '0,1,2,3,5,7,8,9'    => '8-16',
  '0,1,2,3,5,7,9'      => '7-24',
  '0,1,2,3,5,8'        => '6-z40',
  '0,1,2,3,6'          => '5-4',
  '0,1,2,3,6,7'        => '6-5',
  '0,1,2,3,6,7,8'      => '7-7',
  '0,1,2,3,6,7,8,9'    => '8-9',
  '0,1,2,3,6,7,9'      => '7-19',
  '0,1,2,3,6,8'        => '6-z41',
  '0,1,2,3,6,9'        => '6-z42',
  '0,1,2,3,7'          => '5-5',
  '0,1,2,3,7,8'        => '6-z38',
  '0,1,2,4'            => '4-2',
  '0,1,2,4,5'          => '5-3',
  '0,1,2,4,5,6'        => '6-z4',
  '0,1,2,4,5,6,7,9'    => '8-14',
  '0,1,2,4,5,6,8'      => '7-13',
  '0,1,2,4,5,6,8,10'   => '8-24',
  '0,1,2,4,5,6,8,9'    => '8-19',
  '0,1,2,4,5,6,8,9,10' => '9-12',
  '0,1,2,4,5,6,9'      => '7-z17',
  '0,1,2,4,5,7'        => '6-z11',
  '0,1,2,4,5,7,8'      => '7-z38',
  '0,1,2,4,5,7,8,10'   => '8-27',
  '0,1,2,4,5,7,8,9'    => '8-20',
  '0,1,2,4,5,7,9'      => '7-27',
  '0,1,2,4,5,8'        => '6-15',
  '0,1,2,4,5,8,9'      => '7-21',
  '0,1,2,4,6'          => '5-9',
  '0,1,2,4,6,7'        => '6-z12',
  '0,1,2,4,6,7,8'      => '7-15',
  '0,1,2,4,6,7,8,10'   => '8-25',
  '0,1,2,4,6,7,9'      => '7-29',
  '0,1,2,4,6,8'        => '6-22',
  '0,1,2,4,6,8,10'     => '7-33',
  '0,1,2,4,6,8,9'      => '7-30',
  '0,1,2,4,6,9'        => '6-z46',
  '0,1,2,4,7'          => '5-z36',
  '0,1,2,4,7,8'        => '6-z17',
  '0,1,2,4,7,9'        => '6-z47',
  '0,1,2,4,8'          => '5-13',
  '0,1,2,5'            => '4-4',
  '0,1,2,5,6'          => '5-6',
  '0,1,2,5,6,7'        => '6-z6',
  '0,1,2,5,6,7,9'      => '7-20',
  '0,1,2,5,6,8'        => '6-z43',
  '0,1,2,5,6,8,9'      => '7-22',
  '0,1,2,5,6,9'        => '6-z44',
  '0,1,2,5,7'          => '5-14',
  '0,1,2,5,7,8'        => '6-18',
  '0,1,2,5,7,9'        => '6-z48',
  '0,1,2,5,8'          => '5-z38',
  '0,1,2,6'            => '4-5',
  '0,1,2,6,7'          => '5-7',
  '0,1,2,6,7,8'        => '6-7',
  '0,1,2,6,8'          => '5-15',
  '0,1,2,7'            => '4-6',
  '0,1,3'              => '3-2',
  '0,1,3,4'            => '4-3',
  '0,1,3,4,5,6,7,9'    => '8-12',
  '0,1,3,4,5,6,8'      => '7-11',
  '0,1,3,4,5,6,8,9'    => '8-17',
  '0,1,3,4,5,7'        => '6-z10',
  '0,1,3,4,5,7,8'      => '7-z37',
  '0,1,3,4,5,7,8,10'   => '8-26',
  '0,1,3,4,5,7,9'      => '7-26',
  '0,1,3,4,5,8'        => '6-14',
  '0,1,3,4,6'          => '5-10',
  '0,1,3,4,6,7'        => '6-z13',
  '0,1,3,4,6,7,9'      => '7-31',
  '0,1,3,4,6,7,9,10'   => '8-28',
  '0,1,3,4,6,8'        => '6-z24',
  '0,1,3,4,6,8,10'     => '7-34',
  '0,1,3,4,6,8,9'      => '7-32',
  '0,1,3,4,6,9'        => '6-27',
  '0,1,3,4,7'          => '5-16',
  '0,1,3,4,7,8'        => '6-z19',
  '0,1,3,4,7,9'        => '6-z49',
  '0,1,3,4,8'          => '5-z17',
  '0,1,3,5'            => '4-11',
  '0,1,3,5,6'          => '5-z12',
  '0,1,3,5,6,7,9'      => '7-28',
  '0,1,3,5,6,8'        => '6-z25',
  '0,1,3,5,6,8,10'     => '7-35',
  '0,1,3,5,6,9'        => '6-z28',
  '0,1,3,5,7'          => '5-24',
  '0,1,3,5,7,8'        => '6-z26',
  '0,1,3,5,7,9'        => '6-34',
  '0,1,3,5,8'          => '5-27',
  '0,1,3,6'            => '4-13',
  '0,1,3,6,7'          => '5-19',
  '0,1,3,6,7,9'        => '6-30',
  '0,1,3,6,8'          => '5-29',
  '0,1,3,6,9'          => '5-31',
  '0,1,3,7'            => '4-z29',
  '0,1,4'              => '3-3',
  '0,1,4,5'            => '4-7',
  '0,1,4,5,6,7,9'      => '7-z18',
  '0,1,4,5,6,8'        => '6-16',
  '0,1,4,5,7'          => '5-z18',
  '0,1,4,5,7,9'        => '6-31',
  '0,1,4,5,8'          => '5-21',
  '0,1,4,5,8,9'        => '6-20',
  '0,1,4,6'            => '4-z15',
  '0,1,4,6,7,9'        => '6-z50',
  '0,1,4,6,8'          => '5-30',
  '0,1,4,6,9'          => '5-32',
  '0,1,4,7'            => '4-18',
  '0,1,4,7,8'          => '5-22',
  '0,1,4,8'            => '4-19',
  '0,1,5'              => '3-4',
  '0,1,5,6'            => '4-8',
  '0,1,5,6,8'          => '5-20',
  '0,1,5,7'            => '4-16',
  '0,1,5,8'            => '4-20',
  '0,1,6'              => '3-5',
  '0,1,6,7'            => '4-9',
  '0,2,3,4,5,6,7,9'    => '8-10',
  '0,2,3,4,5,6,8'      => '7-8',
  '0,2,3,4,5,7'        => '6-8',
  '0,2,3,4,5,7,9'      => '7-23',
  '0,2,3,4,5,8'        => '6-z39',
  '0,2,3,4,6'          => '5-8',
  '0,2,3,4,6,7,9'      => '7-25',
  '0,2,3,4,6,8'        => '6-21',
  '0,2,3,4,6,9'        => '6-z45',
  '0,2,3,4,7'          => '5-11',
  '0,2,3,5'            => '4-10',
  '0,2,3,5,6,8'        => '6-z23',
  '0,2,3,5,7'          => '5-23',
  '0,2,3,5,7,9'        => '6-33',
  '0,2,3,5,8'          => '5-25',
  '0,2,3,6'            => '4-12',
  '0,2,3,6,7,9'        => '6-z29',
  '0,2,3,6,8'          => '5-28',
  '0,2,3,7'            => '4-14',
  '0,2,4'              => '3-6',
  '0,2,4,5,7,9'        => '6-32',
  '0,2,4,5,8'          => '5-26',
  '0,2,4,6'            => '4-21',
  '0,2,4,6,8'          => '5-33',
  '0,2,4,6,8,10'       => '6-35',
  '0,2,4,6,9'          => '5-34',
  '0,2,4,7'            => '4-22',
  '0,2,4,7,9'          => '5-35',
  '0,2,4,8'            => '4-24',
  '0,2,5'              => '3-7',
  '0,2,5,7'            => '4-23',
  '0,2,5,8'            => '4-27',
  '0,2,6'              => '3-8',
  '0,2,6,8'            => '4-25',
  '0,2,7'              => '3-9',
  '0,3,4,5,8'          => '5-z37',
  '0,3,4,7'            => '4-17',
  '0,3,5,8'            => '4-26',
  '0,3,6'              => '3-10',
  '0,3,6,9'            => '4-28',
  '0,3,7'              => '3-11',
  '0,4,8'              => '3-12',
};

########################################################################
#
# SUBROUTINES

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  $self->{_DEG_IN_SCALE} = int( $param{DEG_IN_SCALE} // $DEG_IN_SCALE );
  if ( $self->{_DEG_IN_SCALE} < 2 ) {
    croak("degrees in scale must be greater than one");
  }

  if ( exists $param{lastn} ) {
    croak "lastn must be number\n" unless looks_like_number $param{lastn};
    $self->{_lastn} = $param{lastn};
  } else {
    $self->{_lastn} = 2;
  }

  # XXX packing not implemented beyond "right" method (via www.mta.ca docs)
  $self->{_packing} = $param{PACKING} // 'right';

  bless $self, $class;
  return $self;
}

########################################################################
#
# Methods of Music

sub circular_permute {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @perms;
  for my $i ( 0 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      $perms[$i][$j] = $pset->[ ( $i + $j ) % @$pset ];
    }
  }
  return \@perms;
}

sub complement {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';

  my %seen;
  @seen{@$pset} = ();
  return [ grep { !exists $seen{$_} } 0 .. $self->{_DEG_IN_SCALE} - 1 ];
}

# Utility, "mirrors" a pitch to be within supplied min/max values as
# appropriate for how many times the pitch "reflects" back within those
# limits, which will depend on which limit is broken and by how much.
sub constrain_pitch {
  my ( $self, $v, $min, $max ) = @_;
  croak "invalid value" if !looks_like_number $v;
  croak "invalid bounds"
    if !looks_like_number $min
      or !looks_like_number $max
      or $min >= $max;
  return $v if $v <= $max and $v >= $min;

  my ( @origins, $overshoot, $direction );
  if ( $v > $max ) {
    @origins   = ( $max, $min );
    $overshoot = abs( $v - $max );
    $direction = -1;
  } else {
    @origins   = ( $min, $max );
    $overshoot = abs( $min - $v );
    $direction = 1;
  }
  my $range    = abs( $max - $min );
  my $register = int( $overshoot / $range );
  if ( $register % 2 == 1 ) {
    @origins = reverse @origins;
    $direction *= -1;
  }
  my $remainder = $overshoot % $range;

  return $origins[0] + $remainder * $direction;
}

sub forte2pcs {
  my ( $self, $forte_number ) = @_;
  return $FORTE2PCS->{ lc $forte_number };
}

sub fnums {
  my ($self) = @_;
  return $FORTE2PCS;
}

sub interval_class_content {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';

  my @nset = sort { $a <=> $b } uniq @$pset;
  croak "pitch set must contain at least two elements\n" if @nset < 2;

  my %icc;
  for my $i ( 1 .. $#nset ) {
    for my $j ( 0 .. $i - 1 ) {
      $icc{
        $self->pitch2intervalclass(
          ( $nset[$i] - $nset[$j] ) % $self->{_DEG_IN_SCALE}
        )
        }++;
    }
  }

  my @icv;
  for my $ics ( 1 .. int( $self->{_DEG_IN_SCALE} / 2 ) ) {
    push @icv, $icc{$ics} || 0;
  }

  return wantarray ? ( \@icv, \%icc ) : \@icv;
}

sub invariance_matrix {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @ivm;
  for my $i ( 0 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      $ivm[$i][$j] = ( $pset->[$i] + $pset->[$j] ) % $self->{_DEG_IN_SCALE};
    }
  }

  return \@ivm;
}

sub invert {
  my ( $self, $pset, $axis ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;
  $axis //= 0;

  my @inverse = @$pset;
  for my $p (@inverse) {
    $p = ( $axis - $p ) % $self->{_DEG_IN_SCALE};
  }

  return \@inverse;
}

# Utility routine to get the last few elements of a list (but never more
# than the whole list, etc).
sub lastn {
  my ( $self, $pset, $n ) = @_;
  croak "cannot get elements of nothing"
    if !defined $pset
      or ref $pset ne 'ARRAY';

  return unless @$pset;

  $n //= $self->{_lastn};
  croak "n of lastn must be number\n" unless looks_like_number $n;

  my $len = @$pset;
  $len = $n if $len > $n;
  $len *= -1;
  return @{$pset}[ $len .. -1 ];
}

sub multiply {
  my ( $self, $pset, $factor ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;
  $factor //= 1;

  return [ map { my $p = $_ * $factor % $self->{_DEG_IN_SCALE}; $p } @$pset ];
}

# Utility methods for get/check/reset of each element in turn of a given
# array reference, with wrap-around. Handy if pulling sequential
# elements off a list, but have much code between the successive calls.
{
  my %seen;

  # get the iterator value for a ref
  sub geti {
    my ( $self, $ref ) = @_;
    return $seen{$ref} || 0;
  }

  # nexti(\@array) - returns subsequent elements of array on each
  # successive call
  sub nexti {
    my ( $self, $ref ) = @_;
    $seen{$ref} ||= 0;
    $ref->[ ++$seen{$ref} % @$ref ];
  }

  # reseti(\@array) - resets counter
  sub reseti {
    my ( $self, $ref ) = @_;
    $seen{$ref} = 0;
  }

  # set the iterator for a ref
  sub seti {
    my ( $self, $ref, $i ) = @_;
    croak "iterator must be number\n" unless looks_like_number($i);
    $seen{$ref} = $i;
  }

  # returns current element, but does not advance pointer
  sub whati {
    my ( $self, $ref ) = @_;
    $seen{$ref} ||= 0;
    $ref->[ $seen{$ref} % @$ref ];
  }
}

sub normal_form {
  my ( $self, $pset ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @nset = sort { $a <=> $b } uniq @$pset;

  return \@nset if @nset == 1;

  my $equivs = $self->circular_permute( \@nset );
  my @order  = 1 .. $#nset;
  if ( $self->{_packing} eq 'right' ) {
    @order = reverse @order;
  } elsif ( $self->{_packing} eq 'left' ) {
    # XXX not sure about this, www.mta.ca instructions not totally
    # clear on the Forte method, and the 7-z18 (0234589) form
    # listed there reduces to (0123589). So, blow up until can
    # figure that out.
    #      unshift @order, pop @order;
    # Also, the inclusion of http://en.wikipedia.org/wiki/Forte_number
    # plus a prime_form call on those pitch sets shows no changes caused
    # by the default 'right' packing method, so sticking with it until
    # learn otherwise.
    die 'left packing method not yet implemented';
  } else {
    croak 'unknown packing method (try the "right" one)';
  }

  my @normal;
  for my $i (@order) {
    my $min_span = $self->{_DEG_IN_SCALE};
    my @min_span_idx;

    for my $eidx ( 0 .. $#$equivs ) {
      my $span =
        ( $equivs->[$eidx][$i] - $equivs->[$eidx][0] )
        % $self->{_DEG_IN_SCALE};
      if ( $span < $min_span ) {
        $min_span     = $span;
        @min_span_idx = $eidx;
      } elsif ( $span == $min_span ) {
        push @min_span_idx, $eidx;
      }
    }

    if ( @min_span_idx == 1 ) {
      @normal = @{ $equivs->[ $min_span_idx[0] ] };
      last;
    } else {
      @$equivs = @{$equivs}[@min_span_idx];
    }
  }

  if ( !@normal ) {
    # nothing unique, pick lowest starting pitch, which is first index
    # by virtue of the numeric sort performed above.
    @normal = @{ $equivs->[0] };
  }

  return \@normal;
}

sub pcs2forte {
  my ( $self, $pset ) = @_;

  if ( !ref $pset ) {
    my @pitches = $pset =~ m/(\d+)/g;
    for my $p (@pitches) {
      $p %= $self->{_DEG_IN_SCALE};
    }
    $pset = \@pitches;
  }

  if ( ref $pset eq 'ARRAY' ) {
    croak "pitch set must contain something\n" if !@$pset;
    $pset = $self->prime_form($pset);
    $pset = join ',', @$pset;
  } else {
    croak "pitch set must be array ref or string\n";
  }

  return $PCS2FORTE->{$pset};
}

sub pitch2intervalclass {
  my ( $self, $pitch ) = @_;

  # ensure member of the tone system, otherwise strange results
  $pitch %= $self->{_DEG_IN_SCALE};

  return $pitch > int( $self->{_DEG_IN_SCALE} / 2 )
    ? $self->{_DEG_IN_SCALE} - $pitch
    : $pitch;
}

# Forte has names for prime forms (3-1 and suchlike) though these do not
# appear to have any easily automated prime form to name algorithm, so
# they will not be supported until someone provides patches or I need to
# learn more about them.
sub prime_form {
  my ( $self, $pset ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @forms = $self->normal_form($pset);
  push @forms, $self->normal_form( $self->invert( $forms[0] ) );

  for my $s (@forms) {
    $s = $self->transpose( $s, $self->{_DEG_IN_SCALE} - $s->[0] )
      if $s->[0] != 0;
  }

  my @prime;
  if ( "@{$forms[0]}" eq "@{$forms[1]}" ) {
    @prime = @{ $forms[0] };
  } else {
    # look for most compact to the left
    my @sums = ( 0, 0 );
  PITCH: for my $i ( 0 .. $#$pset ) {
      for my $j ( 0 .. 1 ) {
        $sums[$j] += $forms[$j][$i];
      }
      if ( $sums[0] < $sums[1] ) {
        @prime = @{ $forms[0] };
        last PITCH;
      } elsif ( $sums[0] > $sums[1] ) {
        @prime = @{ $forms[1] };
        last PITCH;
      }
    }
  }

  if ( !@prime ) {
    use Data::Dumper;
    warn Dumper \@forms;
    die "TODO oh noes";
  }

  return \@prime;
}

sub retrograde {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;
  return [ reverse @$pset ];
}

sub rotate {
  my ( $self, $pset, $r ) = @_;
  croak "rotate value must be integer\n"
    if !defined $r
      or $r !~ /^-?\d+$/;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @rot;
  if ( $r == 0 ) {
    @rot = @$pset;
  } else {
    for my $i ( 0 .. $#$pset ) {
      $rot[$i] = $pset->[ ( $i - $r ) % @$pset ];
    }
  }

  return \@rot;
}

# Utility method to rotate a list to a named element (for example "gis"
# in a list of note names, see etude no.2 for results of heavy use of
# such rotations).
sub rotateto {
  my ( $self, $pset, $what ) = @_;

  croak "nothing to rotate on\n"
    unless defined $pset
      and ref $pset eq 'ARRAY'
      and @$pset;
  croak "nothing to search on\n" unless defined $what;

  my $index = firstidx { $_ eq $what } @$pset;
  croak "no such element $what\n" if $index == -1;
  return $self->rotate( $pset, -$index );
}

# XXX probably should disallow changing this on the fly, esp. if allow
# method chaining, as it could throw off results in wacky ways.
sub scale_degrees {
  my ( $self, $dis ) = @_;
  if ( defined $dis ) {
    croak "scale degrees value must be positive integer greater than 1\n"
      if !defined $dis
        or $dis !~ /^\d+$/
        or $dis < 2;
    $self->{_DEG_IN_SCALE} = $dis;
  }
  return $self->{_DEG_IN_SCALE};
}

sub set_complex {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my $iset = $self->invert($pset);
  my $dis  = $self->scale_degrees;

  my @plex = $pset;
  for my $i ( 1 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      if ( $j == 0 ) {
        $plex[$i][0] = $iset->[$i];
      } else {
        $plex[$i][$j] = ( $pset->[$j] + $iset->[$i] ) % $dis;
      }
    }
  }

  return \@plex;
}

sub subsets {
  my ( $self, $pset, $len ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  my @nset = uniq @$pset;
  croak "pitch set must be larger than 1 element" unless @nset > 1;
  croak "invalid length" if defined $len and ( $len < 1 or $len > @nset );

  $len ||= @nset - 1;
  my $p = Algorithm::Permute->new( \@nset, $len );

  my ( @subsets, %seen );
  while ( my @res = sort { $a <=> $b } $p->next ) {
    push @subsets, \@res unless $seen{ join '', @res }++;
  }
  return \@subsets;
}

sub tcis {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my %seen;
  @seen{@$pset} = ();

  my @tcis;
  for my $i ( 0 .. $self->{_DEG_IN_SCALE} - 1 ) {
    $tcis[$i] = 0;
    for my $p ( @{ $self->transpose_invert( $pset, $i ) } ) {
      $tcis[$i]++ if exists $seen{$p};
    }
  }
  return \@tcis;
}

sub tcs {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my %seen;
  @seen{@$pset} = ();

  my @tcs = scalar @$pset;
  for my $i ( 1 .. $self->{_DEG_IN_SCALE} - 1 ) {
    $tcs[$i] = 0;
    for my $p ( @{ $self->transpose( $pset, $i ) } ) {
      $tcs[$i]++ if exists $seen{$p};
    }
  }
  return \@tcs;
}

sub transpose {
  my ( $self, $pset, $t ) = @_;
  croak "transpose value must be integer\n"
    if !defined $t
      or $t !~ /^-?\d+$/;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @tset = @$pset;

  for my $p (@tset) {
    $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
  }
  return \@tset;
}

sub transpose_invert {
  my ( $self, $pset, $t, $axis ) = @_;
  croak "transpose value must be integer\n"
    if !defined $t
      or $t !~ /^-?\d+$/;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;
  $axis //= 0;

  my $tset = $self->invert( $pset, $axis );

  for my $p (@$tset) {
    $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
  }
  return $tset;
}

sub variances {
  my ( $self, $pset1, $pset2 ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset1 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset1;
  croak "pitch set must be array ref\n" unless ref $pset2 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset2;

  my ( @union, @intersection, @difference, %count );
  for my $p ( @$pset1, @$pset2 ) {
    $count{$p}++;
  }
  for my $p ( sort { $a <=> $b } keys %count ) {
    push @union, $p;
    push @{ $count{$p} > 1 ? \@intersection : \@difference }, $p;
  }
  return
    wantarray ? ( \@intersection, \@difference, \@union ) : \@intersection;
}

sub zrelation {
  my ( $self, $pset1, $pset2 ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset1 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset1;
  croak "pitch set must be array ref\n" unless ref $pset2 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset2;

  my @ic_vecs;
  for my $ps ( $pset1, $pset2 ) {
    push @ic_vecs, scalar $self->interval_class_content($ps);
  }
  return ( "@{$ic_vecs[0]}" eq "@{$ic_vecs[1]}" ) ? 1 : 0;
}

1;
__END__

=head1 NAME

Music::AtonalUtil - atonal music analysis and composition

=head1 SYNOPSIS

  use Music::AtonalUtil;
  my $atu = Music::AtonalUtil->new;

Then see below for methods.

=head1 DESCRIPTION

This module contains a variety of routines suitable for atonal music
composition and analysis (plus a bunch of other routines I could find
no better home for). See the methods below, the test suite, and the
C<atonal-util> command line interface (in L<App::MusicTools>) for ideas
on how to use these routines. L</"SEE ALSO"> has links to documentation
on atonal analysis.

Warning! There may be errors due to misunderstanding of atonal theory by
the autodidactic author. If in doubt, compare the results of this code
with other software or documentation available.

Warning! The interface may change in the future (e.g. more OOish, so can
do things like ->foo->bar->as_string and the like).

=head1 METHODS

By default, a 12-tone system is assumed. Input values are (often) not
checked whether they reside inside this space. Most methods accept a
pitch set (an array reference consisting of a list of pitch numbers),
and most return new array references containing the results of the
operation. Some basic sanity checking is done on the input, which may
cause the code to B<croak> if something is awry. Elements of the pitch
sets are not checked whether they reside inside the 12-tone basis
(pitch numbers through 11), so input data may need to be first reduced
as follows:

  my $atu = Music::AtonalUtil->new;

  my $pitch_set = [25,18,42,5];
  for my $p (@$pitch_set) { $p %= $atu->scale_degrees }

  say "Result: @$pitch_set";      # Result: 1 6 6 5

Results from the various methods should reside within the
B<scale_degrees>, unless the method returns something else.

=over 4

=item B<new> I<parameter_pairs ...>

Constructor. The degrees in the scale can be adjusted via:

  Music::AtonalUtil->new(DEG_IN_SCALE => 17);

or some other positive integer greater than one, to use a non-12-tone
basis for subsequent method calls. This value can be set or inspected
via the B<scale_degrees> call. (Note: non-12-tone scales are in theory
supported, but have not really been tested.)

=item B<circular_permute> I<pitch_set>

Takes a pitch set, returns an array reference of pitch set references:

  $atu->circular_permute([1,2,3]);   # [[1,2,3],[2,3,1],[3,1,2]]

This is used by the B<normal_form> method, internally. This permutation
is identical to inversions in tonal theory, but different from the
B<invert> method offered by this module. See also B<rotate> to rotate a
pitch set by a particular amount.

=item B<complement> I<pitch_set>

Returns the pitches of the scale degrees not set in the passed
pitch set.

  $atu->complement([1,2,3]);    # [0,4,5,6,7,8,9,10,11]

Calling B<prime_form> on the result will find the abstract complement of
the original set.

=item B<constrain_pitch> I<pitch>, I<min>, I<max>

Constrains the supplied pitch to reside within the supplied minimum and
maximum limits, by "reflecting" the pitch back off the limits. For
example, given the min and max limits of 6 and 12:

  pitch  ... 10 11 12 13 14 15 16 17 18 19 20 21 ...
  result ... 10 11 12 11 10  9  8  7  6  7  8  9 ...

This may be of use in a L<Music::LilyPondUtil> C<*_pitch_hook> function
to keep the notes within a certain range (modulus math, by contrast,
produces a sawtooth pattern with occasional leaps).

=item B<forte2pcs> I<forte_number>

Given a Forte Number (such as C<6-z44> or C<6-Z44>), returns the
corresponding pitch set as an array reference, or nothing if an unknown
Forte Number is supplied.

=item B<fnums>

Returns hash reference of which keys are Forte Numbers and values are
array references to the corresponding pitch sets.

=item B<interval_class_content> I<pitch_set>

Given a pitch set with at least two elements, returns an array reference
(and in list context also a hash reference) representing the interval-
class vector information. Pitch sets with similar ic content tend to
sound the same (see also B<zrelation>).

This vector is also known as a pitch-class interval (PIC) vector or
absolute pitch-class interval (APIC) vector:

https://en.wikipedia.org/wiki/Interval_vector

Uses include an indication of invariance under transposition; see
the B<invariants> mode of C<eg/atonal-util> for the display of
invariant pitches.

=item B<invariance_matrix> I<pitch_set>

Returns reference to an array of references that comprise the invariance
under Transpose(N)Inversion operations on the given pitch set. Probably
easier to use the B<invariants> mode of C<eg/atonal-util> or use
equivalent code.

=item B<invert> I<pitch_set> I<optional_axis>

Inverts the given pitch set, by default around the 0 axis, within the
degrees in scale. Returns resulting pitch set as an array reference.
Some examples or styles assume rotation with an axis of 6, for example:

https://en.wikipedia.org/wiki/Set_%28music%29#Serial

Has the "retrograde-inverse transposition" of C<0 11 3> becoming C<4 8
7>. This can be reproduced via:

  my $p = $atu->retrograde([0,11,3]);
  $p = $atu->invert($p, 6);
  $p = $atu->transpose($p, 1);

=item B<lastn> I<array_ref>, I<n>

Returns the last N elements of the supplied array reference, or the
entire list if N > the number of elements available. Returns nothing if
the array reference is empty, but otherwise will throw an exception if
something is awry. (Handy if saving up recent pitches or notes, then are
using some filter to exclude "recent" pitches or notes from what is next
being generated, to avoid repeated notes.)

=item B<multiply> I<pitch_set> I<factor>

Multiplies the supplied pitch set by the given factor, modulates the
results by the B<scale_degrees>, and returns the results as an array
reference.

=item B<nexti> I<array ref>

Returns the next item from the supplied array reference. Loops around to
beginning of list if bounds of the array are exceeded. Caches the index
for subsequent lookups. Part of the B<geti>, B<nexti>, B<reseti>,
B<seti>, B<whati> set of routines, which are documented here:

=over 4

=item B<geti> I<array ref>

Returns current position in array (which may be larger than the number
of elements in the list, as the routines modulate the iterator down as
necessary to fit the reference).

=item B<reseti> I<array ref>

Sets the iterator to zero for the given array reference.

=item B<seti> I<array ref>, I<index>

Sets the iterator to the given value.

=item B<whati> I<array ref>

Returns the value of what is currently pointed at in the array
reference. Does not advance the index.

=back

=item B<normal_form> I<pitch_set>

Returns the normal form of the passed pitch set, via a "packed from the
right" method outlined in the www.mta.ca link, below, so may return
different normal forms than the Allen Forte method. There is stub code
for the Allen Forte method in this module, though I lack enough
information to verify if that code is correct.

=item B<pcs2forte> I<pitch_set>

Given a pitch set, returns the Forte Number of that set.

  $atu->pcs2forte([qw/0 1 2 5 6 9/]);  # array ref form

  $atu->pcs2forte('[0,1,2,5,6,9]');    # string forms are okay
  $atu->pcs2forte('0,1,2,5,6,9');      # as well

The Forte Numbers use lowercase C<z>, for example C<6-z44>. An undefined
value will be returned if no Forte Number exists for the pitch set.

=item B<pitch2intervalclass> I<pitch>

Returns the interval class a given pitch belongs to (0 is 0, 11 maps
down to 1, 10 down to 2, ... and 6 is 6 for the standard 12 tone
system). Used internally by the B<interval_class_content> method.

=item B<prime_form> I<pitch_set>

Returns the prime form of a given pitch set (via B<normal_form> and
various other operations on the passed pitch set).

=item B<retrograde> I<pitch_set>

Fancy term for the reverse of a list. Returns reference to array of said
reversed data.

=item B<rotate> I<pitch_set> I<rotate_by>

Rotates the members given pitch set by the given integer. Returns array
reference of the resulting pitch set. B<circular_permute> performs all
the possible rotations for a pitch set.

=item B<rotateto> I<pitch_set> I<what>

Rotates (via B<rotate>) a given array reference to the named element
(using string comparisons). Returns array reference of the thus
rotated set. Throws an exception if anything goes wrong with the input
or search.

The rotation uses C<firstidx> to find the first element, but then
rotates negative that index. This may be a concern if there are multiple
matching elements in a given input list.

=item B<scale_degrees> I<optional_integer>

Without arguments, returns the number of scale degrees (12 by default).
If passed a positive integer greater than two, sets the scale degrees to
that. Note that changing this will change the results from almost all
the methods this module offers, and would only be used for calculations
involving a subset of the Western 12 tone system, or some exotic scale
with more than 12 tones.

=item B<set_complex> I<pitch_set>

Creates the set complex, or a 2D array with the pitch set as the column
headers, pitch set inversion as the row headers, and the combination of
those two for the intersection of the row and column headers. Returns
reference to the resulting array of arrays.

Ideally the first pitch of the input pitch set should be 0 (so the input
may need reduction to B<prime_form> first).

=item B<subsets> I<pitch_set> I<optional_length>

Returns the subsets of a given pitch set, of default length one minus
the magnitude of the input pitch set (that is, whatever two element
pitch sets exist for a given three element pitch set). The custom length
allows subsets of 1 <= len <= magnitude_of_pitch_set results to be
returned, for example three element pitch subsets of a given five
element pitch set.

The underlying permutation library might sort or otherwise return the
results in arbitrary orderings. Sorry about that.

=item B<tcs> I<pitch_set>

Returns array reference consisting of the transposition common-tone
structure (TCS) for the given pitch set, that is, for each of the
possible transposition operations under the B<scale_degrees> in
question, how many common tones there are with the original set.

=item B<tcis> I<pitch_set>

Like B<tcs>, except uses B<transpose_invert> instead of just B<transpose>.

=item B<transpose> I<pitch_set> I<integer>

Transposes the given pitch set by the given integer value, returns that
result as an array reference.

=item B<transpose_invert> I<pitch_set> I<integer>

Performs B<invert> on given pitch set, then transposition as per
B<transpose>, returning the resulting array reference.

=item B<variances> I<pitch_set1> I<pitch_set2>

Given two pitch sets, in scalar context returns the shared notes of
those two pitch sets as an array reference. In list context, returns the
shared notes (intersection), difference, and union all as array
references.

=item B<zrelation> I<pitch_set1> I<pitch_set2>

Given two pitch sets, returns true if the two sets share the same
B<interval_class_content>, false if not.

=back

=head1 BUGS

=head2 Reporting Bugs

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

http://github.com/thrig/Music-AtonalUtil

=head2 Known Issues

Poor naming conventions and standards of underlying music theory and any
associated mistakes in understanding thereof by the author.

=head1 SEE ALSO

Reference and learning material:

=over 4

=item *

The perlreftut, perldsc, and perllol perldocs to learn more about perl
references, as the pitch sets utilize array references and arrays of
array references.

=item *

http://www.mta.ca/faculty/arts-letters/music/pc-set_project/pc-set_new/

=item *

Musimathics, Vol. 1, p.311-317

=item *

"The Structure of Atonal Music" by Allen Forte.

=item *

http://en.wikipedia.org/wiki/Forte_number

=item *

L<Music::Chord::Positions> for a more tonal module.

=item *

L<Music::LilyPondUtil> for where the pitch-number to lilypond-note-name
code has been moved to, and L<App::MusicTools> for where the command
line utilities have been stashed.

=back

=head1 AUTHOR

Jeremy Mates, E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14.2 or, at
your option, any later version of Perl 5 you may have available.

=cut
