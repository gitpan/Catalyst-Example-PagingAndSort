package Catalyst::Helper::Model::CDBISweet;
use version; $VERSION = qv('0.0.2');
use strict;
use Class::DBI::Loader;
use File::Spec;

=head1 NAME

Catalyst::Helper::Model::CDBI - Helper for CDBI Models

=head1 SYNOPSIS

    script/create.pl model CDBI CDBI dsn user password

=head1 DESCRIPTION

Helper for CDBI Model.

=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class as well as placeholders
for each table.

=item mk_comptest

Makes tests for the CDBI Model.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper, $dsn, $user, $pass ) = @_;
    $helper->{dsn}  = $dsn  || '';
    $helper->{user} = $user || '';
    $helper->{password} = $pass || '';
    $helper->{rel} = $dsn =~ /sqlite|pg|mysql/i ? 1 : 0;
    my $file = $helper->{file};
    $helper->{classes} = [];
    $helper->render_file( 'cdbiclass', $file );
    #push( @{ $helper->{classes} }, $helper->{class} );
    return 1 unless $dsn;
    my $loader = Class::DBI::Loader->new(
        dsn       => $dsn,
        user      => $user,
        password  => $pass,
        namespace => $helper->{class}
    );

    my $path = $file;
    $path =~ s/\.pm$//;
    $helper->mk_dir($path);

    for my $c ( $loader->classes ) {
        $helper->{tableclass} = $c;
        $helper->{tableclass} =~ /\W*(\w+)$/;
        my $f = $1;
        $helper->{tablename}  = lc $f;
        $helper->{columns} =  [ grep { !/^id$/ } $c->columns() ];
        my $p = File::Spec->catfile( $path, "$f.pm" );
        if($dsn =~ /dbi:Pg/){
            $helper->{PostgreSQL} = 1;
        }
        $helper->render_file( 'tableclass', $p );
        push( @{ $helper->{classes} }, $c );
    }
    return 1;
}

sub mk_comptest {
    my ( $self, $helper ) = @_;
    my $test = $helper->{test};
    my $name = $helper->{name};
    for my $c ( @{ $helper->{classes} } ) {
        $helper->{tableclass} = $c;
        $helper->{tableclass} =~ /\:\:(\w+)\:\:(\w+)$/;
        my $prefix;
        unless ( $1 eq 'M' ) { $prefix = "$name\::$2" }
        else { $prefix = $2 }
        $prefix =~ s/::/_/g;
        $prefix = lc $prefix;
        my $test = $helper->next_test($prefix);
        $helper->render_file( 'test', $test );
    }
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Zbigniew Lukasiak, C<zz bb yy@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__DATA__

__cdbiclass__
package [% class %];
use strict;
use base qw/Catalyst::Model::CDBI::Sweet Class::DBI::FromForm Class::DBI::AsForm /;
__PACKAGE__->connection('[% dsn %]', '[% user %]', '[% password %]', { AutoCommit => 1 , RaiseError=>1});

=head1 NAME

[% class %] - CDBI::Sweet Model Component


=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

__tableclass__
package [% tableclass %];
use base [% class %];
use strict;
__PACKAGE__->table('[% tablename %]');
__PACKAGE__->columns(All => qw/id [% FOR col=columns; col _ ' '; END %]/);
[% IF PostgreSQL %]
__PACKAGE__->sequence('[% tablename %]_id_seq');
[% END %]

use strict;

=head1 NAME

[% tableclass %] - CDBI:Sweet Model Component Table Class

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;

__test__
use Test::More tests => 2;
use_ok( Catalyst::Test, '[% app %]' );
use_ok('[% tableclass %]');
