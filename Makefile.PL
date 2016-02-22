use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MooseX::Storage::IO::Redis',
    AUTHOR           => q{Marco Masetti <marco.masetti@softeco.it>},
    VERSION_FROM     => 'lib/MooseX/Storage/IO/Redis.pm',
    ABSTRACT_FROM    => 'lib/MooseX/Storage/IO/Redis.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'                    => 0,
    },
    PREREQ_PM => {
        'Moose'                         => 0,
        'Redis'                         => 0,
        'MooseX::Role::Parameterized'   => 0,
        'namespace::autoclean'          => 0,
        'Try::Tiny'                     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooseX-Storage-IO-Redis-*' },
);
