package Music::AtonalUtil;

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;

our $VERSION = '0.02';

my $DEG_IN_SCALE = 12;

########################################################################
#
# SUBROUTINES

sub new {
  my ( $class, $self, %param ) = @_;
  $self //= {};

  $self->{_DEG_IN_SCALE} = $param{DEG_IN_SCALE} // $DEG_IN_SCALE;
  $self->{_packing}      = $param{PACKING}      // 'right';

  bless $self, $class;
  return $self;
}

########################################################################
#
# Methods of Music

# Circular permutation, same as taking inversions in tonal harmony.
# 'invert' is a different operation.
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

# Given a pitch set, returns the complement of that set as an array
# reference.
sub complement {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';

  my %seen;
  @seen{@$pset} = ();
  return [ grep { !exists $seen{$_} } 0 .. $self->{_DEG_IN_SCALE} - 1 ];
}

# Given a pitch set as an array reference containing at least two
# elements, returns an array reference (and in list context also a hash
# reference) representing the same interval-class vector information.
sub interval_class_content {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain at least two elements\n" if @$pset < 2;

  my %icc;
  for my $i ( 1 .. $#$pset ) {
    for my $j ( 0 .. $i - 1 ) {
      $icc{
        pitch2intervalclass(
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

# Given a pitch set, returns reference to an array of references that
# comprise the invarience under Transpose(N)-Inversion of the pitch set.
sub invariance_matrix {
  my ( $self, $pset ) = @_;
  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @ivm;
  for my $i ( 0 .. $#$pset ) {
    for my $j ( 0 .. $#$pset ) {
      $ivm[$i][$j] = $pset->[$i] + $pset->[$j];
    }
  }

  return \@ivm;
}

# Invert pitch set about axis (0 by default). Differs from tonal
# inversion (use circular permutation for that). Returns array ref of
# inverse pitch set.
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

# Given a pitch set (array ref of integergs), returns the normal form of
# that pitch set as an array ref. A second optional argument specifies
# whether to pack the pitch set "to the left" (Allen Forte, The
# Structure of Atonal Music) or "from the right" (various other authors;
# specify the word 'right' for this method). This needs to be handled
# better, either via a packing=>value hash(ref) or as part of an OO
# constructor.
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
    my $equivs = circular_permute($pset);

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

# Given an pitch, returns interval class that pitch belongs to. This is
# the circle of pitches folded in half along the zero to halfway point
# for the degrees in the system, assumes equal temperament, etc.
sub pitch2intervalclass {
  my ( $self, $pitch ) = @_;
  return $pitch > int( $self->{_DEG_IN_SCALE} / 2 )
    ? $self->{_DEG_IN_SCALE} - $pitch
    : $pitch;
}

# Given a pitch set (array ref of integers), returns array reference
# containing the prime form of the pitch set. A second argument
# specifies the packing method (see normal_form docs).
#
# Forte has names for prime forms (3-1 and suchlike) though these do not
# appear to have any easily automated prime form to name algorithm, so
# they will not be supported until someone provides patches or I need to
# learn more about them.
sub prime_form {
  my ( $self, $pset ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset;

  my @forms = normal_form($pset);
  push @forms, normal_form( invert( $forms[0] ) );

  for my $s (@forms) {
    $s = transpose( $s, $self->{_DEG_IN_SCALE} - $s->[0] ) if $s->[0] != 0;
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

# Adjusts pitch set members by the specified integer amount. Atonal
# theory typically only transposes up (so 1 up to 12 and then modulus
# instead of 1 down to 0 and then modulus), but this routine offers
# negative transpositions, if desired. Returns array reference
# containing the transposed pitch set.
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

# Routine to show variance between two pitch sets (typically a starting
# set and the the "transposition" or "inversion and transposition" of
# that first set). In scalar context, returns array ref of the
# intersection of the two sets; in list context, returns array ref of
# the intersection, difference, and union of the sets.
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
  for my $p ( keys %count ) {
    push @union, $p;
    push @{ $count{$p} > 1 ? \@intersection : \@difference }, $p;
  }
  return
    wantarray ? ( \@intersection, \@difference, \@union ) : \@intersection;
}

# Given two pitch set array references, returns true or false depending
# on whether those pitch sets are Z-related or not (that is, share the
# same interval-class vector).
sub zrelation {
  my ( $self, $pset1, $pset2 ) = @_;

  croak "pitch set must be array ref\n" unless ref $pset1 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset1;
  croak "pitch set must be array ref\n" unless ref $pset2 eq 'ARRAY';
  croak "pitch set must contain something\n" if !@$pset2;

  my @ic_vecs;
  for my $ps ( $pset1, $pset2 ) {
    push @ic_vecs, scalar interval_class_content($ps);
  }
  return ( "@{$ic_vecs[0]}" eq "@{$ic_vecs[1]}" ) ? 1 : 0;
}

1;
__END__

=head1 NAME

Music::AtonalUtil - Perl extension for atonal music analysis and composition

=head1 SYNOPSIS

  use Music::AtonalUtil;
  blah blah blah

=head1 DESCRIPTION

This module contains a variety of routines suitable for atonal music
composition and analysis.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over 4

=item *

http://www.mta.ca/faculty/arts-letters/music/pc-set_project/pc-set_new/

=item *

Musimathics, Vol. 1, p.311-317

=back

=head1 AUTHOR

Jeremy Mates, E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14.2 or, at
your option, any later version of Perl 5 you may have available.

=cut
