package MooseX::Storage::IO::Redis;
#============================================================ -*-perl-*-

=head1 NAME

MooseX::Storage::IO::Redis - the Redis driver of the Moosex::Storage::IO
interface.

=head1 VERSION

0.01

=cut

our $VERSION='0.01';

=head1 SYNOPSIS

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'Redis' => {
      key_attr  => 'doc_id',              # which attribute should keep the unique id
      connect   => { server => 'localhost:8080' },
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

Now you can store/load your class:

  use MyDoc;

  # Create a new instance of MyDoc
  my $doc = MyDoc->new(
      doc_id   => 'foo12',
      title    => 'Foo',
      body     => 'blah blah',
      tags     => [qw(horse yellow angry)],
      authors  => {
          jdoe => {
              name  => 'John Doe',
              email => 'jdoe@gmail.com',
              roles => [qw(author reader)],
          },
          bsmith => {
              name  => 'Bob Smith',
              email => 'bsmith@yahoo.com',
              roles => [qw(editor reader)],
          },
      },
  );

  # Save it to cache (will be stored using key "foo12")
  # if no key attribute 
  my $doc_id = $doc->store();

  # Check if the passed id exists in the data store
  if ( not MyDoc->exists('foo12') ) {
    $doc->store();
  }

  # Load the saved data into a new instance
  my $doc2 = MyDoc->load('foo12');

  # This should say 'Bob Smith'
  print $doc2->authors->{bsmith}{name};

=head1 DESCRIPTION

This driver handles object persistency on a Redis data store.

=head1 AUTHOR

Marco Masetti (marco.masetti @ softeco.it )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015 Marco Masetti (marco.masetti at softeco.it). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES/METHODS

=cut

#========================================================================
use strict;
use warnings;
use feature 'state';
use Redis ();
use MooseX::Role::Parameterized;
use namespace::autoclean;
use Try::Tiny;
use Carp 'croak';

parameter key_attr => ( isa => 'Str', required => 1 );
parameter connect  => ( 
    isa => 'HashRef',
    default => sub { { server => '127.0.0.1:6379' } }
);

role {
    my $p = shift;

    our $connect = $p->connect;

    requires 'pack';
    requires 'unpack';

    sub _connect {
        state $redis;
        try { 
            $redis = Redis->new( %$connect );
            return $redis;
        } catch {
            croak "Error getting a Redis object: $_\n";
        };

    };

    has 'redis' => (
        is      => 'ro',
        isa     => 'Redis',
        lazy    => 1,
        traits  => [ 'DoNotSerialize' ],
        default => sub { return _connect() }
    );

#=============================================================

=head2 store

=head3 INPUT

=head3 OUTPUT

    Object id/undef in case of errors

=head3 DESCRIPTION

    Stores data, dies in case of errors.
    In case an object with the same id is already stored
    it is replaced with the new one.

=cut

#=============================================================
    method store => sub {
        my $self = shift;
        my $key_attr = $p->key_attr;
        my $key_val = $self->$key_attr;
    
        # as Redis hashes cannot be nested we freeze everything into
        # a json string to be sure...
        my $data = $self->freeze();
    
        try {
            return $self->redis->set( $key_val, $data );
        } catch {
            die ("Error inserting object $_");
        };
    };

#=============================================================

=head2 load

=head3 INPUT

    $key_value  : the value of the key attribute
    %args       : see MooseX::Storage::Basic unpack() info for details

=head3 OUTPUT

The object or undef in case of error.

=head3 DESCRIPTION

Gets the collection object, search for the document with
the passed id value, returns the blessed document.

=cut

#=============================================================
    method load => sub {
        my ( $class, $key_value, %args ) = @_;

        my $redis = $class->_connect()
            or die "Error connecting to Redis $@";

        my $key_attr = $p->key_attr;
        $key_value // die "undefined value for key attr $key_attr";

        my $data = $redis->get( $key_value ) or return undef;
        my $obj = $class->thaw($data);
        return $obj;
    };

#=============================================================

=head2 exists

=head3 INPUT

    the object key

=head3 OUTPUT

    1 if object exists, otherwise undef

=head3 DESCRIPTION

    Checks that object exists.

=cut

#=============================================================
    method exists => sub {
        my ( $class, $key_value, %args ) = @_;

        my $redis = $class->_connect()
            or die "Error connecting to Redis $@";

        my $key_attr = $p->key_attr;
        $key_value // die "undefined value for key attr $key_attr";

        return $redis->exists( $key_value );
    };
};

1;
