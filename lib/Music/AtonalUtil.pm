package Music::AtonalUtil;

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;

our $VERSION = '0.08';

my $DEG_IN_SCALE = 12;

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

sub interval_class_content {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain at least two elements\n" if @$pset < 2;

  my %icc;
  for my $i ( 1 .. $#$pset ) {
    for my $j ( 0 .. $i - 1 ) {
      $icc{
        $self->pitch2intervalclass(
          ( $pset->[$i] - $pset->[$j] ) % $self->{_DEG_IN_SCALE}
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

sub normal_form {
  my ( $self, $pset ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my %seen;
  @$pset = sort { $a <=> $b } grep { !$seen{$_}++ } @$pset;

  my @normal;
  if ( @$pset == 1 ) {
    @normal = @$pset;
  } else {
    my $equivs = $self->circular_permute($pset);

    my @order = 1 .. $#$pset;
    if ( $self->{_packing} eq 'right' ) {
      @order = reverse @order;
    } elsif ( $self->{_packing} eq 'left' ) {
      # XXX not sure about this, www.mta.ca instructions not totally
      # clear on the Forte method, and the 7-z18 (0234589) form
      # listed there reduces to (0123589). So, blow up until can
      # figure that out.
      #      unshift @order, pop @order;
      die 'left packing method not yet implemented';
    } else {
      croak 'unknown packing method';
    }

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
  }

  return \@normal;
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

sub scale_degrees {
  my ( $self, $dis ) = @_;
  $self->{_DEG_IN_SCALE} = int($dis) if $dis and $dis > 1;
  return $self->{_DEG_IN_SCALE};
}

sub set_complex {
  my ( $self, $pset ) = @_;

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

Music::AtonalUtil - Perl extension for atonal music analysis and composition

=head1 SYNOPSIS

  use Music::AtonalUtil;
  my $atu = Music::AtonalUtil->new;

Then see below for methods.

=head1 DESCRIPTION

This module contains a variety of routines suitable for atonal music
composition and analysis. See the methods below, the test suite, and the
C<eg/atonal-util> command line interface for ideas on how to use these
routines. L<"SEE ALSO"> has links to documentation on atonal analysis.

=head1 METHODS

By default, a 12-tone system is assumed. Input values are not checked
whether they reside inside this space. Most methods accept a pitch set
(an array reference consisting of a list of pitch numbers), and most
return new array references containing the results of the operation.
Some basic sanity checking is done on the input, which may cause the
code to B<croak> if something is awry. Elements of the pitch sets are
not checked whether they reside inside the 12-tone basis (pitch numbers
0 through 11), so input data may need to be first reduced as follows:

  my $atu = Music::AtonalUtil->new;

  my $pitch_set = [25,18,42,5];
  for my $p (@$pitch_set) { $p %= $atu->scale_degrees }

  say "Result: @$pitch_set";      # Result: 1 6 6 5

Results from the various methods should reside within the 12-tone basis.

=over 4

=item B<new> I<parameter pairs ...>

Constructor. The degrees in the scale can be adjusted via:

  Music::AtonalUtil->new(DEG_IN_SCALE => 17);

or some other positive integer greater than one, to use a non-12-tone
basis for subsequent method calls. This value can be set or inspected
via the B<scale_degrees> call.

=item B<circular_permute> I<pitch set>

Takes a pitch set, returns an array reference of pitch set references:

  $atu->circular_permute([1,2,3]);   # [[1,2,3],[2,3,1],[3,1,2]]

This is used by the B<normal_form> method, internally. This permutation
is identical to inversions in tonal theory, but different from the
B<invert> method offered by this module. See also B<rotate> to rotate a
pitch set by a particular amount.

=item B<complement> I<pitch set>

Returns the pitches of the scale degrees not set in the passed
pitch set.

  $atu->complement([1,2,3]);    # [0,4,5,6,7,8,9,10,11]

=item B<interval_class_content> I<pitch set>

Given a pitch set with at least two elements, returns an array reference
(and in list context also a hash reference) representing the interval-
class vector information. Pitch sets with similar ic content tend to
sound the same (see also B<zrelation>).

=item B<invariance_matrix> I<pitch set>

Returns reference to an array of references that comprise the invarience
under Transpose(N)Inversion operations on the given pitch set. (With
code, probably easier to iterate through all the T and T(N)I operations
than learn how to read this table.)

=item B<invert> I<pitch set> I<optional axis>

Inverts the given pitch set, by default around the 0 axis, within the
degrees in scale. Returns resulting pitch set as an array reference.

=item B<normal_form> I<pitch set>

Returns the normal form of the passed pitch set, via a "packed from the
right" method outlined in the www.mta.ca link, below, so may return
different normal forms than the Allen Forte method. There is stub code
for the Allen Forte method in this module, though I lack enough
information to verify if that code is correct.

=item B<pitch2intervalclass> I<pitch>

Returns the interval class a given pitch belongs to (0 is 0, 11 maps
down to 1, 10 down to 2, ... and 6 is 6 for the standard 12 tone
system). Used internally by the B<interval_class_content> method.

=item B<prime_form> I<pitch set>

Returns the prime form of a given pitch set (via B<normal_form> and
various other operations on the passed pitch set).

=item B<retrograde> I<pitch set>

Fancy term for the reverse of a list. Returns reference to array of said
reversed data.

=item B<rotate> I<pitch set> I<rotate by>

Rotates the members given pitch set by the given integer. Returns array
reference of the resulting pitch set. B<circular_permute> performs all
the possible rotations for a pitch set.

=item B<scale_degrees> I<optional integer>

Without arguments, returns the number of scale degrees (12 by default).
If passed a positive integer greater than two, sets the scale degrees to
that. Note that changing this will change the results from almost all
the methods this module offers, and would only be used for calculations
involving a subset of the Western 12 tone system, or some exotic scale
with more than 12 tones.

=item B<set_complex> I<pitch set>

Creates the set complex, or a 2D array with the pitch set as the column
headers, pitch set inversion as the row headers, and the combination of
those two for the intersection of the row and column headers. Returns
reference to the resulting array of arrays.

Ideally the first pitch of the input pitch set should be 0 (so the input
may need reduction to B<prime_form> first).

=item B<transpose> I<pitch set> I<integer>

Transposes the given pitch set by the given integer value, returns that
result as an array reference. Transpositional equivalence and
Transposition+Inversion equivalence can be iterated through by
appropriate calls to this method and also B<invert>:

  my $atu = Music::AtonalUtil->new;
  my $ps = [ 0, 1, 5, 8 ];

  my ( @transpose, @transpose_invert );

  for my $i ( 0 .. 11 ) {
    push @transpose, $atu->transpose( $ps, $i );
    push @transpose_invert, $atu->invert( $transpose[-1] );
  }

=item B<variances> I<pitch set1> I<pitch set2>

Given two pitch sets, in scalar context returns the shared notes of
those two pitch sets as an array reference. In list context, returns the
shared notes (intersection), difference, and union all as array
references.

=item B<zrelation> I<pitch set1> I<pitch set2>

Given two pitch sets, returns true if the two sets share the same
B<interval_class_content>, false if not.

=back

=head1 SEE ALSO

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

L<Music::Chord::Positions> for a more tonal module.

=back

=head1 AUTHOR

Jeremy Mates, E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14.2 or, at
your option, any later version of Perl 5 you may have available.

=cut
