use strict;
use warnings;
use Test::More;
use Redis;

#First, configure your Moose class via a call to Storage:

BEGIN {

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  my $redis = Redis->new(server => '127.0.0.1:6379');
  $redis->flushall();

  with Storage(
      format => 'JSON',           # this will provide us freeze/thaw capabilities...
      io => [ 'Redis' => {
          key_attr   => 'doc_id',   # which attribute should keep the unique id
          connect   => { server => '127.0.0.1:6379' },
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;
}

#Now you can store/load your class to the cache you defined in cache_args:

BEGIN {
    use_ok( 'MooseX::Storage::IO::Redis' ) || print "Bail out!\n";
    use_ok( 'MyDoc' );
}

diag( "Testing MooseX::Storage::IO::Redis $MooseX::Storage::IO::Redis::VERSION, Perl $], $^X" );

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

  # Save it to cache (will be stored using key "mydoc-foo12")
  # if no key attribute 
is( MyDoc->exists('foo12'), 0, "ok, object doesn't exist yet...");
ok( my $doc_id = $doc->store(), 'store' );
is( MyDoc->exists('foo12'), 1, "ok, object now exists...");

# Load the saved data into a new instance
my $doc2 = MyDoc->load('foo12');

# This should say 'Bob Smith'
is ( $doc2->authors->{bsmith}{name}, 'Bob Smith', 'got right data back' );

$doc2->authors->{bsmith}{name} = 'Bob Smith Junior';

ok( $doc2->store(), 'storing again...');
my $doc3 = MyDoc->load('foo12');

# This should say now 'Bob Smith Junior'
is ( $doc3->authors->{bsmith}{name}, 'Bob Smith Junior', 'got right data back' );

done_testing;
