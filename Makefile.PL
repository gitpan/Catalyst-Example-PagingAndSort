use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Example::PagingAndSort',
    AUTHOR              => '<Zbigniew Lukasiak> <<zz bb yy @ gmail.com>>',
    VERSION_FROM        => 'lib/Catalyst/Example/PagingAndSort.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Example/PagingAndSort.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Catalyst'      => 0,
        'URI::Escape'   => 0,
        'HTML::Entities' => 0,
        'File::Spec'    => 0,
        'Catalyst::View::TT' => 0.20,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Example-PagingAndSort-*' },
    EXE_FILES           => ['script/pagingandsort.pl'],
);

