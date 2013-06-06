# -*- Perl -*-
#
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
use List::MoreUtils qw/firstidx lastidx uniq/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '1.02';

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

# Utility, convert a scale_degrees-bit number into a pitch set.
#            7   3  0
# 137 -> 000010001001 -> [0,3,7]
sub bits2pcs {
  my ( $self, $bs ) = @_;

  my @pset;
  for my $p ( 0 .. $self->{_DEG_IN_SCALE} - 1 ) {
    push @pset, $p if $bs & ( 1 << $p );
  }
  return \@pset;
}

sub circular_permute {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'pitch set must contain something' if !@$pset;

  my @perms;
  for my $i ( 0 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      $perms[$i][$j] = $pset->[ ( $i + $j ) % @$pset ];
    }
  }
  return \@perms;
}

sub complement {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  my %seen;
  @seen{@$pset} = ();
  return [ grep { !exists $seen{$_} } 0 .. $self->{_DEG_IN_SCALE} - 1 ];
}

sub fnums { $FORTE2PCS }

sub forte2pcs {
  my ( $self, $forte_number ) = @_;
  return $FORTE2PCS->{ lc $forte_number };
}

sub interval_class_content {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  my @nset = sort { $a <=> $b } uniq @$pset;
  croak 'pitch set must contain at least two elements' if @nset < 2;

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

sub intervals2pcs {
  my $self        = shift;
  my $start_pitch = shift;
  my $iset        = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'interval set must contain something' if !@$iset;

  $start_pitch //= 0;
  $start_pitch = int $start_pitch;

  my @pset = $start_pitch;
  for my $i (@$iset) {
    push @pset, ( $pset[-1] + $i ) % $self->{_DEG_IN_SCALE};
  }

  return \@pset;
}

sub invariance_matrix {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'pitch set must contain something' if !@$pset;

  my @ivm;
  for my $i ( 0 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      $ivm[$i][$j] = ( $pset->[$i] + $pset->[$j] ) % $self->{_DEG_IN_SCALE};
    }
  }

  return \@ivm;
}

sub invert {
  my $self = shift;
  my $axis = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'pitch set must contain something' if !@$pset;

  $axis //= 0;
  $axis = int $axis;

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
  croak 'cannot get elements of nothing'
    if !defined $pset
    or ref $pset ne 'ARRAY';

  return unless @$pset;

  $n //= $self->{_lastn};
  croak 'n of lastn must be number' unless looks_like_number $n;

  my $len = @$pset;
  $len = $n if $len > $n;
  $len *= -1;
  return @{$pset}[ $len .. -1 ];
}

sub multiply {
  my $self   = shift;
  my $factor = shift;
  my $pset   = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
  croak 'pitch set must contain something' if !@$pset;

  $factor //= 1;
  $factor = int $factor;

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
    croak 'iterator must be number' unless looks_like_number($i);
    $seen{$ref} = $i;
  }

  # returns current element, but does not advance pointer
  sub whati {
    my ( $self, $ref ) = @_;
    $seen{$ref} ||= 0;
    $ref->[ $seen{$ref} % @$ref ];
  }
}

sub new {
  my ( $class, %param ) = @_;
  my $self = {};

  $self->{_DEG_IN_SCALE} = int( $param{DEG_IN_SCALE} // $DEG_IN_SCALE );
  if ( $self->{_DEG_IN_SCALE} < 2 ) {
    croak 'degrees in scale must be greater than one';
  }

  if ( exists $param{lastn} ) {
    croak 'lastn must be number' unless looks_like_number $param{lastn};
    $self->{_lastn} = $param{lastn};
  } else {
    $self->{_lastn} = 2;
  }

  # XXX packing not implemented beyond "right" method (via www.mta.ca docs)
  $self->{_packing} = $param{PACKING} // 'right';

  bless $self, $class;
  return $self;
}

sub normal_form {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my %origmap;
  for my $p (@$pset) {
    push @{ $origmap{ $p % $self->{_DEG_IN_SCALE} } }, $p;
  }
  if ( keys %origmap == 1 ) {
    return wantarray ? ( [ keys %origmap ], \%origmap ) : [ keys %origmap ];
  }
  my @nset = sort { $a <=> $b } keys %origmap;

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
    die 'left packing method not yet implemented (sorry)';
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

  return wantarray ? ( \@normal, \%origmap ) : \@normal;
}

# Utility, convert a pitch set into a scale_degrees-bit number:
#                7   3  0
# [0,3,7] -> 000010001001 -> 137
sub pcs2bits {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my $bs = 0;
  for my $p ( map $_ % $self->{_DEG_IN_SCALE}, @$pset ) {
    $bs |= 1 << $p;
  }
  return $bs;
}

sub pcs2forte {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  $pset = $self->prime_form($pset);
  $pset = join ',', @$pset;
  return $PCS2FORTE->{$pset};
}

sub pcs2intervals {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain at least two elements' if @$pset < 2;

  my @intervals;
  for my $i ( 1 .. $#{$pset} ) {
    push @intervals, $pset->[$i] - $pset->[ $i - 1 ];
  }

  return \@intervals;
}

sub pcs2str {
  my $self = shift;
  croak 'must supply a pitch set' if !defined $_[0];

  my $str;
  if ( ref $_[0] eq 'ARRAY' ) {
    $str = '[' . join( ',', @{ $_[0] } ) . ']';
  } elsif ( $_[0] =~ m/,/ ) {
    $str = '[' . $_[0] . ']';
  } else {
    $str = '[' . join( ',', @_ ) . ']';
  }
  return $str;
}

sub pitch2intervalclass {
  my ( $self, $pitch ) = @_;

  # ensure member of the tone system, otherwise strange results
  $pitch %= $self->{_DEG_IN_SCALE};

  return $pitch > int( $self->{_DEG_IN_SCALE} / 2 )
    ? $self->{_DEG_IN_SCALE} - $pitch
    : $pitch;
}

# XXX tracking of original pitches would be nice, though complicated, as
# ->invert would need to be modifed or a non-modulating version used
sub prime_form {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my @forms = scalar $self->normal_form($pset);
  push @forms, scalar $self->normal_form( $self->invert( 0, $forms[0] ) );

  for my $set (@forms) {
    $set = $self->transpose( $self->{_DEG_IN_SCALE} - $set->[0], $set )
      if $set->[0] != 0;
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
    die "XXX oh noes";
  }

  return \@prime;
}

# Utility, "mirrors" a pitch to be within supplied min/max values as
# appropriate for how many times the pitch "reflects" back within those
# limits, which will depend on which limit is broken and by how much.
sub reflect_pitch {
  my ( $self, $v, $min, $max ) = @_;
  croak 'pitch must be a number' if !looks_like_number $v;
  croak 'limits must be numbers and min less than max'
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

sub retrograde {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  return [ reverse @$pset ];
}

sub rotate {
  my $self = shift;
  my $r    = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'rotate value must be integer'
    if !defined $r
    or $r !~ /^-?\d+$/;
  croak 'pitch set must contain something' if !@$pset;

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
# in a list of note names, see my etude no.2 for results of heavy use of
# such rotations).
sub rotateto {
  my $self = shift;
  my $what = shift;
  my $dir  = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'nothing to search on' unless defined $what;
  croak 'nothing to rotate on' if !@$pset;

  $dir //= 1;
  my $method = $dir < 0 ? \&lastidx : \&firstidx;

  my $index = $method->( sub { $_ eq $what }, @$pset );
  croak "no such element $what" if $index == -1;
  return $self->rotate( -$index, $pset );
}

# XXX probably should disallow changing this on the fly, esp. if allow
# method chaining, as it could throw off results in wacky ways.
sub scale_degrees {
  my ( $self, $dis ) = @_;
  if ( defined $dis ) {
    croak 'scale degrees value must be positive integer greater than 1'
      if !defined $dis
      or $dis !~ /^\d+$/
      or $dis < 2;
    $self->{_DEG_IN_SCALE} = $dis;
  }
  return $self->{_DEG_IN_SCALE};
}

sub set_complex {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my $iset = $self->invert( 0, $pset );
  my $dis = $self->scale_degrees;

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
  my $self = shift;
  my $len  = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  my @nset = uniq map { my $p = $_ % $self->{_DEG_IN_SCALE}; $p } @$pset;
  croak 'pitch set must contain two or more unique pitches' if @nset < 2;
  if ( defined $len ) {
    croak 'length must be less than size of pitch set (but not zero)'
      if $len >= @nset
      or $len == 0;
    if ( $len < 0 ) {
      $len = @nset + $len;
      croak 'negative length exceeds magnitude of pitch set' if $len < 1;
    }
  } else {
    $len = @nset - 1;
  }

  my $p = Algorithm::Permute->new( \@nset, $len );

  my ( @subsets, %seen );
  while ( my @res = sort { $a <=> $b } $p->next ) {
    push @subsets, \@res unless $seen{ join '', @res }++;
  }
  return \@subsets;
}

sub tcis {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my %seen;
  @seen{@$pset} = ();

  my @tcis;
  for my $i ( 0 .. $self->{_DEG_IN_SCALE} - 1 ) {
    $tcis[$i] = 0;
    for my $p ( @{ $self->transpose_invert( $i, 0, $pset ) } ) {
      $tcis[$i]++ if exists $seen{$p};
    }
  }
  return \@tcis;
}

sub tcs {
  my $self = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'pitch set must contain something' if !@$pset;

  my %seen;
  @seen{@$pset} = ();

  my @tcs = scalar @$pset;
  for my $i ( 1 .. $self->{_DEG_IN_SCALE} - 1 ) {
    $tcs[$i] = 0;
    for my $p ( @{ $self->transpose( $i, $pset ) } ) {
      $tcs[$i]++ if exists $seen{$p};
    }
  }
  return \@tcs;
}

sub transpose {
  my $self = shift;
  my $t    = shift;
  my @tset = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;

  croak 'transpose value not set' if !defined $t;
  croak 'pitch set must contain something' if !@tset;

  $t = int $t;
  for my $p (@tset) {
    $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
  }
  return \@tset;
}

sub transpose_invert {
  my $self = shift;
  my $t    = shift;
  my $axis = shift;
  my $pset = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];

  croak 'transpose value not set' if !defined $t;
  croak 'pitch set must contain something' if !@$pset;

  $axis //= 0;
  my $tset = $self->invert( $axis, $pset );

  $t = int $t;
  for my $p (@$tset) {
    $p = ( $p + $t ) % $self->{_DEG_IN_SCALE};
  }
  return $tset;
}

sub variances {
  my ( $self, $pset1, $pset2 ) = @_;

  croak 'pitch set must be array ref' unless ref $pset1 eq 'ARRAY';
  croak 'pitch set must contain something' if !@$pset1;
  croak 'pitch set must be array ref' unless ref $pset2 eq 'ARRAY';
  croak 'pitch set must contain something' if !@$pset2;

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

  croak 'pitch set must be array ref' unless ref $pset1 eq 'ARRAY';
  croak 'pitch set must contain something' if !@$pset1;
  croak 'pitch set must be array ref' unless ref $pset2 eq 'ARRAY';
  croak 'pitch set must contain something' if !@$pset2;

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

  use Music::AtonalUtil ();
  my $atu = Music::AtonalUtil->new;

  my $nf = $atu->normal_form([0,3,7]);
  my $pf = $atu->prime_form(0, 4, 7);
  ...

Though see below for the (many) other methods.

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

=head1 METHODS

By default, a 12-tone system is assumed. Input values are (hopefully)
mapped to reside inside this space where necessary. Most methods accept
a pitch set (an array reference consisting of a list of pitch numbers,
or just a list of such numbers), and most return array references
containing the results. Some (but not much) sanity checking is done on
the input, which may cause the code to B<croak> if something is awry.

Results from the various methods should reside within the
B<scale_degrees>, unless the method returns something else. Integer math
is (often) assumed.

=over 4

=item B<new> I<parameter_pairs ...>

Constructor. The degrees in the scale can be adjusted via:

  Music::AtonalUtil->new(DEG_IN_SCALE => 17);

or some other positive integer greater than one, to use a non-12-tone
basis for subsequent method calls. This value can be set or inspected
via the B<scale_degrees> call. B<Note that while non-12-tone systems are
in theory supported, they have not really been tested.>

=item B<bits2pcs> I<number>

Converts a number into a I<pitch_set>, and returns said set as an array
reference. Performs opposite role of the B<pcs2bits> method. Will not
consider bits beyond B<scale_degrees> in the input number.

=item B<circular_permute> I<pitch_set>

Takes a pitch set (array reference to list of pitches or just a
list of such), and returns an array reference of pitch set
references as follows:

  $atu->circular_permute([1,2,3]);   # [[1,2,3],[2,3,1],[3,1,2]]

This is used by the B<normal_form> method, internally. This permutation
is identical to inversions in tonal theory, but is different from the
B<invert> method offered by this module. See also B<rotate> to rotate a
pitch set by a particular amount, or B<rotateto> to search for something
to rotate to.

=item B<complement> I<pitch_set>

Returns the pitches of the scale degrees not set in the passed pitch set
(an array reference to list of pitches or just a list of such).

  $atu->complement([1,2,3]);    # [0,4,5,6,7,8,9,10,11]

Calling B<prime_form> on the result will find the abstract complement of
the original set, whatever that means.

=item B<fnums>

Returns hash reference of which keys are Forte Numbers and values are
array references to the corresponding pitch sets. This reference should
perhaps not be fiddled with, unless the fiddler desires different
results for the B<forte2pcs> and B<pcs2forte> calls.

=item B<forte2pcs> I<forte_number>

Given a Forte Number (such as C<6-z44> or C<6-Z44>), returns the
corresponding pitch set as an array reference, or C<undef> if an unknown
Forte Number is supplied.

=item B<interval_class_content> I<pitch_set>

Given a pitch set with at least two elements, returns an array reference
(and in list context also a hash reference) representing the
interval-class vector information. Pitch sets with similar ic content
tend to sound the same (see also B<zrelation>).

This vector is also known as a pitch-class interval (PIC) vector or
absolute pitch-class interval (APIC) vector:

L<https://en.wikipedia.org/wiki/Interval_vector>

Uses include an indication of invariance under transposition; see also
the B<invariants> mode of C<atonal-util> of L<App::MusicTools> for the
display of invariant pitches.

=item B<intervals2pcs> I<start_pitch>, I<interval_set>

Given a starting pitch (set to C<0> if unsure) and an interval set (a
list of intervals or array reference of such), converts those intervals
into a pitch set, returned as an array reference.

=item B<invariance_matrix> I<pitch_set>

Returns reference to an array of references that comprise the invariance
under Transpose(N)Inversion operations on the given pitch set. Probably
easier to use the B<invariants> mode of C<atonal-util> of
L<App::MusicTools>, unless you know what you are doing.

=item B<invert> I<axis>, I<pitch_set>

Inverts the given pitch set, within the degrees in scale. Set the
I<axis> to C<0> if unsure. Returns resulting pitch set as an array
reference. Some examples or styles assume rotation with an axis of C<6>,
for example:

L<https://en.wikipedia.org/wiki/Set_%28music%29#Serial>

Has the "retrograde-inverse transposition" of C<0 11 3> becoming C<4 8
7>. This can be reproduced via:

  my $p = $atu->retrograde(0,11,3);
  $p = $atu->invert(6, $p);
  $p = $atu->transpose(1, $p);

=item B<lastn> I<array_ref>, I<n>

Utility method. Returns the last N elements of the supplied array
reference, or the entire list if N exceeds the number of elements
available. Returns nothing if the array reference is empty, but
otherwise will throw an exception if something is awry.

=item B<multiply> I<factor>, I<pitch_set>

Multiplies the supplied pitch set by the given factor, modulates the
results by the B<scale_degrees> setting, and returns the results as an
array reference.

=item B<nexti> I<array ref>

Utility method. Returns the next item from the supplied array reference.
Loops around to the beginning of the list if the bounds of the array are
exceeded. Caches the index for subsequent lookups. Part of the B<geti>,
B<nexti>, B<reseti>, B<seti>, and B<whati> set of routines, which are
documented here:

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

Returns two values in list context; first, the normal form of the passed
pitch set as an array reference, and secondly, a hash reference linking
the normal form values to array references containing the input pitch
numbers those normal form values represent. An example may clarify:

  my ($ps, $lookup) = $atu->normal_form(60, 64, 67, 72); # c' e' g' c''

=over

=item *

C<$ps> is C<[0,4,7]>, as C<60> and C<72> are equivalent pitches, so both
get mapped to C<0>.

=item *

C<$lookup> contains hash keys C<0>, C<4>, and C<7>, where C<4> points to
an array reference containing C<64>, C<7> to an array reference
containing C<67>, and C<0> an array reference containing both C<60> and
C<72>. This allows software to answer "what original pitches of
the input are X" type questions.

=back

Use C<scalar> context or the following to select just the normal form
array reference:

  my $just_the_nf_thanks = ($atu->normal_form(...))[0];

The "packed from the right" method outlined in the www.mta.ca link
(L</"SEE ALSO">) is employed, so may return different normal forms than
the Allen Forte method. There is stub code for the Allen Forte method in
this module, though I lack enough information to verify if that code is
correct. The Forte Numbers on Wikipedia match that of the www.mta.ca
link method.

See also B<normalize> of L<Music::NeoRiemannianTonnetz> for a different
take on normal and prime forms.

=item B<pcs2bits> I<pitch_set>

Converts a I<pitch_set> into a B<scale_degrees>-bit number.

                 7   3  0
  [0,3,7] -> 000010001001 -> 137

These can be inspected via C<printf>, and the usual bit operations
applied as desired.

  my $mask = $atu->pcs2bits(0,3,7);
  sprintf '%012b', $mask;           # 000010001001

  if ( $mask == ( $atu->pcs2bits($other_pset) & $mask ) ) {
    # $other_pset has all the same bits on as $mask does
    ...
  }

=item B<pcs2forte> I<pitch_set>

Given a pitch set, returns the Forte Number of that set. The Forte
Numbers use lowercase C<z>, for example C<6-z44>. C<undef> will be
returned if no Forte Number exists for the pitch set.

=item B<pcs2intervals> I<pitch_set>

Given a pitch set of at least two elements, returns the list of
intervals between those pitch elements. This list is returned as an
array reference.

=item B<pcs2str> I<pitch_set>

Given a pitch set (or string with commas in it) returns the pitch set as
a string in C<[0,1,2]> form.

  $atu->pcs2str([0,3,7])   # "[0,3,7]"
  $atu->pcs2str(0,3,7)     # "[0,3,7]"
  $atu->pcs2str("0,3,7")   # "[0,3,7]"

=item B<pitch2intervalclass> I<pitch>

Returns the interval class a given pitch belongs to (0 is 0, 11 maps
down to 1, 10 down to 2, ... and 6 is 6 for the standard 12 tone
system). Used internally by the B<interval_class_content> method.

=item B<prime_form> I<pitch_set>

Returns the prime form of a given pitch set (via B<normal_form> and
various other operations on the passed pitch set) as an array reference.

See also B<normalize> of L<Music::NeoRiemannianTonnetz> for a different
take on normal and prime forms.

=item B<reflect_pitch> I<pitch>, I<min>, I<max>

Utility method. Constrains the supplied pitch to reside within the
supplied minimum and maximum limits, by "reflecting" the pitch back off
the limits. For example, given the min and max limits of 6 and 12:

  pitch  ... 10 11 12 13 14 15 16 17 18 19 20 21 ...
  result ... 10 11 12 11 10  9  8  7  6  7  8  9 ...

This may be of use in a L<Music::LilyPondUtil> C<*_pitch_hook> function
to keep the notes within a certain range (modulus math, by contrast,
produces a sawtooth pattern with occasional leaps).

=item B<retrograde> I<pitch_set>

Fancy term for the C<reverse> of a list. Returns reference to array of
said reversed list.

=item B<rotate> I<rotate_by>, I<pitch_set>

Rotates the members given pitch set by the given integer. Returns an
array reference of the resulting pitch set. (B<circular_permute>
performs all the possible rotations for a pitch set.)

=item B<rotateto> I<what>, I<dir>, I<pitch_set>

Utility method. Rotates (via B<rotate>) a given array reference to the
desired element I<what> (using string comparisons). Returns an array
reference of the thus rotated set. Throws an exception if anything goes
wrong with the input or search.

I<what> is searched for from the first element and subsequent elements,
assuming a positive I<dir> value. Set a negative I<dir> to invert the
direction of the search.

=item B<scale_degrees> I<optional_integer>

Without arguments, returns the number of scale degrees (12 by default).
If passed a positive integer greater than two, sets the scale degrees to
that. Note that changing this will change the results from almost all
the methods this module offers, and has not been tested.

=item B<set_complex> I<pitch_set>

Computes the set complex, or a 2D array with the pitch set as the column
headers, pitch set inversion as the row headers, and the combination of
those two for the intersection of the row and column headers. Returns
reference to the resulting array of arrays.

Ideally the first pitch of the input pitch set should be 0 (so the input
may need reduction to B<prime_form> first).

=item B<subsets> I<length>, I<pitch_set>

Returns the subsets of a given pitch set. I<length> should be, say, C<-1>
to select for pitch sets of one element less, or a positive value of
a magnitude less than the pitch set to reduce to a specific size.

  $atu->subsets(-1, [0,3,7])  # different ways to say same thing
  $atu->subsets( 2, [0,3,7])

It may make sense to first run the I<pitch_set> through B<normal_form>
or B<prime_form> to normalize the data. Or not, depending.

The underlying permutation library might sort or otherwise return the
results in arbitrary orderings. Sorry about that.

=item B<tcs> I<pitch_set>

Returns array reference consisting of the transposition common-tone
structure (TCS) for the given pitch set, that is, for each of the
possible transposition operations under the B<scale_degrees> in
question, how many common tones there are with the original set.

=item B<tcis> I<pitch_set>

Like B<tcs>, except uses B<transpose_invert> instead of just
B<transpose>.

=item B<transpose> I<transpose_by>, I<pitch_set>

Transposes the given pitch set by the given integer value in
I<transpose_by>. Returns the result as an array reference.

=item B<transpose_invert> I<transpose_by>, I<axis>, I<pitch_set>

Performs B<invert> on given pitch set (set I<axis> to C<0> if unsure),
then transposition as per B<transpose>. Returns the result as an array
reference.

=item B<variances> I<pitch_set1>, I<pitch_set2>

Given two pitch sets, in scalar context returns the shared notes of
those two pitch sets as an array reference. In list context, returns the
shared notes (intersection), difference, and union as array references.

=item B<zrelation> I<pitch_set1>, I<pitch_set2>

Given two pitch sets, returns true if the two sets share the same
B<interval_class_content>, false if not.

=back

=head1 CHANGES

Version 1.0 reordered and otherwise mucked around with calling
conventions (mostly to allow either an array reference or a list of
values for pitch sets), but not the return values. Except for
B<normal_form>, which obtained additional return values, so you can
figure out which of the input pitches map to what (a feature handy for
L<Music::NeoRiemannianTonnetz> related operations, or so I hope).

Otherwise I generally try not to break the interface. Except when I do.

=head1 BUGS

=head2 Reporting Bugs

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<http://github.com/thrig/Music-AtonalUtil>

=head2 Known Issues

Poor naming conventions and vague and conflicting standards of music
theory on top of any mistakes in understanding thereof by the author.

Also, it would be nice to deal with a "Pitch" object that knows how to
return the pitch modulus the C<scale_degrees> via some method (but that
would likely entail a Project that would unify a whole bunch of
C<Music::*> modules into some grand unified PerlMusic thingy, though I
am busy doing other things, so will not be writing that).

=head1 SEE ALSO

Reference and learning material:

=over 4

=item *

The perlreftut, perldsc, and perllol perldocs to learn more about perl
references, as the pitch sets utilize array references and arrays of
array references.

=item *

L<http://www.mta.ca/faculty/arts-letters/music/pc-set_project/pc-set_new/>

=item *

Musimathics, Vol. 1, p.311-317

=item *

"The Structure of Atonal Music" by Allen Forte.

=item *

L<http://en.wikipedia.org/wiki/Forte_number>

=item *

L<Music::Chord::Positions> and L<Music::NeoRiemannianTonnetz> for other
means of wrangling music.

=item *

L<Music::LilyPondUtil> for where the pitch-number to lilypond-note-name
code has been moved to, and L<App::MusicTools> for where the command
line utilities have been stashed, e.g. C<atonal-util>.

=back

=head1 AUTHOR

Jeremy Mates, E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.16 or, at
your option, any later version of Perl 5 you may have available.

=cut
