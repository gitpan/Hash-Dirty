package Hash::Dirty;

use warnings;
use strict;

=head1 NAME

Hash::Dirty - Keep track of whether a hash is dirty or not

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Hash::Dirty;

    my %hash;
    tie %hash, qw/Hash::Dirty/, { a => 1 };

    (tied %hash)->is_dirty; # Nope, not dirty yet.

    $hash{a} = 1;
    (tied %hash)->is_dirty; # Still not dirty yet.

    $hash{b} = 2;
    (tied %hash)->is_dirty; # Yes, now it's dirty

    (tied %hash)->dirty_keys; # ( b )

    $hash{a} = "hello";
    (tied %hash)->dirty_keys; # ( a, b )

    (tied %hash)->dirty_values; # ( "hello", 2 )

    (tied %hash)->dirty } # { a => 1, b => 1 }

    (tied %hash)->reset;
    (tied %hash)->is_dirty; # Nope, not dirty anymore.

    $hash{c} = 3;
    (tied %hash)->is_dirty; # Yes, dirty again.

    # %hash is { a => "hello", b => 2, c => 3 }
    (tied %hash)->dirty_slice } # { c => 3 }

    # Alternatively:

    use Hash::Dirty;

    my $hash = Hash::Dirty::hash;
    $hash = Hash::Dirty->new;
    
    $hash->{a} = 1 # Etc., etc.

=head1 DESCRIPTION

Hash::Dirty will keep track of the dirty keys in a hash, letting you which values changed.

Currently, Hash::Dirty will only inspect a hash shallowly, that is, it does not deeply compare
the contents of supplied values (say a HASH reference, ARRAY reference, or some other opaque object).

This module was inspired by DBIx::Class::Row

=cut

use Tie::Hash;
use base qw/Tie::StdHash/;

=head1 FUNCTIONS

=head2 hash( <hash> )

Creates a new Hash::Dirty object and returns the tied hash reference, per Hash::Dirty->new.

If supplied, will use <hash> as the storage (initializing the object accordingly)

sub hash {
    return __PACKAGE__->new(@_);
}

=cut

sub TIEHASH {
    my ($class, $storage) = @_;
    $storage ||= {};
    return bless { dirty => {}, storage => $storage }, $class;
}

=head1 METHODS 

=cut

=head2 Hash::Dirty->>new( <hash> )

Creates a new Hash::Dirty object and returns the tied hash reference.

If supplied, will use <hash> as the storage (initializing the object accordingly)

=cut

sub new {
    my $class = shift;
    my %hash;
    tie %hash, $class, @_;
    return \%hash;
}

=head2 $hash->is_dirty

Returns 1 if the hash is dirty at all, 0 otherwise 

=head2 $hash->is_dirty ( <key> )

Returns 1 if <key> is dirty, 0 otherwise

=head2 $hash->is_dirty ( $key, $key, ..., )

Returns 1 if any <key> is dirty, 0 otherwise

=cut

sub is_dirty {
    my $self = shift; 
    if (@_) {
        for my $key (@_) {
            return 1 if exists $self->{dirty}->{$key};
        }
    }
    else {
        return 1 if $self->dirty_keys;
    }
    return 0;
}

=head2 $hash->reset

Resets the hash to non-dirty status

This method affects the dirtiness only, it does not erase or alter the hash in anyway

=cut

sub reset {
    my $self = shift; 
    $self->{dirty} = {};
}

=head2 $hash->dirty

Returns a hash indicating which keys are dirty

In scalar context, returns a hash reference

=cut

sub dirty {
    my $self = shift; 
    my %dirty = %{ $self->{dirty} };
    return wantarray ? %dirty : \%dirty;
}

=head2 $hash->dirty_slice

Returns a hash slice containg only the dirty keys and values

In scalar context, returns a hash reference

=cut

sub dirty_slice {
    my $self = shift; 
    my %slice = map { $_ => $self->{storage}{$_} } $self->dirty_keys;
    return wantarray? %slice : \%slice;
}

=head2 $hash->dirty_keys

Returns a list of dirty keys

=cut

sub dirty_keys {
    my $self = shift; 
    return keys %{ $self->{dirty} };
}

=head2 $hash->dirty_values

Returns a list of dirty values

=cut

sub dirty_values {
    my $self = shift; 
    return map { $self->{storage}{$_} } $self->dirty_keys;
}

sub STORE {
    my ($self, $key, $value) = @_;

    my $storage = $self->{storage};
    my $new = $value;
    my $old = $storage->{$key};
    $storage->{$key} = $new;
    # Taken from DBIx::Class::Row::set_column
    $self->{dirty}{$key} = 1 if (defined $old ^ defined $new) || (defined $old && $old ne $new);
    return $new;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-dirty at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Dirty>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Dirty

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Dirty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Dirty>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Dirty>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Dirty>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Hash::Dirty
