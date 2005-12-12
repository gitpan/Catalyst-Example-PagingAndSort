#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use Getopt::Long;
use Pod::Usage;
use YAML 'LoadFile';
use File::Spec;
use File::Slurp;
use Catalyst::Helper;

my $help    = 0;
my $nonew   = 0;
my $scripts = 0;
my $short   = 0;
my $dsn;
my $duser;
my $dpassword;
my $appname;

GetOptions(
    'help|?'  => \$help,
    'nonew'   => \$nonew,
    'scripts' => \$scripts,
    'short'   => \$short,
    'name=s'    => \$appname,
    'dsn=s'     => \$dsn,
    'user=s'    => \$duser,
    'password=s'=> \$dpassword
);


pod2usage(1) if ( $help || !$appname );

my $helper =
  Catalyst::Helper->new(
    { '.newfiles' => !$nonew, 'scripts' => $scripts, 'short' => $short } );
pod2usage(1) unless $helper->mk_app( $appname );

my $appdir = $appname;
$appdir =~ s/::/-/g;
local $FindBin::Bin = File::Spec->catdir($appdir, 'script');
$helper->mk_component ( $appname, 'view', 'TT', 'TT');

$helper->mk_component ( $appname, 'model', 'CDBI', 'CDBISweet',
    $dsn, $duser, $dpassword
);

$helper->mk_component ( $appname, 'controller', 'PagingAndSort', 'PagingAndSort',
    $dsn, $duser, $dpassword
);

my @appdirs = split /::/, $appname;
$appdirs[$#appdirs] .= '.pm';
my $appfile = File::Spec->catdir ( $appdir, 'lib',  @appdirs ) ;
my $appfilecont = read_file($appfile);
$appfilecont =~ s{use Catalyst qw/-Debug Static::Simple/}{use Catalyst qw/-Debug Static::Simple FormValidator DefaultEnd/};
$appfilecont =~ s{__PACKAGE__->config.*}{
__PACKAGE__->config(
    name => 'My::App',
    'View::TT' => {
        WRAPPER      => 'PagingAndSort/wrapper.tt',
    },
);
};

write_file($appfile, $appfilecont) or die "Cannot write main application file";

1;

__END__

=head1 NAME

pagingandsort.pl - Bootstrap a Catalyst application example

=head1 SYNOPSIS

pagingandsort.pl [options] 

 Options:
   -help       display this help and exits
   -nonew      don't create a .new file where a file to be created exists
   -scripts    update helper scripts only
   -short      use short types, like C instead of Controller...
   -name       application-name
   -dsn        dsn
   -user       database user
   -password   database password

 application-name must be a valid Perl module name and can include "::"

 Examples:
    pagingandsort.pl -name=My::App -dsn='dbi:Pg:dbname=CE' -user=zby -password='pass'



=head1 DESCRIPTION

The C<catalyst.pl> script bootstraps a Catalyst application example, creating 
a directory structure populated with skeleton files.  

The application name must be a valid Perl module name.  The name of the
directory created is formed from the application name supplied, with double
colons replaced with hyphens (so, for example, the directory for C<My::App> is
C<My-App>).

Using the example application name C<My::App>, the application directory will
contain the following items:

=over 4

=item README

a skeleton README file, which you are encouraged to expand on

=item Build.PL

a C<Module::Build> build script

=item Changes

a changes file with an initial entry for the creation of the application

=item Makefile.PL

an old-style MakeMaker script.  Catalyst uses the C<Module::Build> system so
this script actually generates a Makeifle that invokes the Build script.

=item lib

contains the application module (C<My/App.pm>) and
subdirectories for model, view, and controller components (C<My/App/M>,
C<My/App/V>, and C<My/App/C>).  

=item root

root directory for your web document content.  This is left empty.

=item script

a directory containing helper scripts:

=over 4

=item C<my_app_create.pl>

helper script to generate new component modules

=item C<my_app_server.pl>

runs the generated application within a Catalyst test server, which can be
used for testing without resorting to a full-blown web server configuration.

=item C<my_app_cgi.pl>

runs the generated application as a CGI script

=item C<my_app_fastcgi.pl>

runs the generated application as a FastCGI script


=item C<my_app_test.pl>

runs an action of the generated application from the comand line.

=back

=item t

test directory

=back


The application module generated by the C<catalyst.pl> script is functional,
although it reacts to all requests by outputting a friendly welcome screen.


=head1 NOTE

Neither C<catalyst.pl> nor the generated helper script will overwrite existing
files.  In fact the scripts will generate new versions of any existing files,
adding the extension C<.new> to the filename.  The C<.new> file is not created
if would be identical to the existing file.  

This means you can re-run the scripts for example to see if newer versions of
Catalyst or its plugins generate different code, or to see how you may have
changed the generated code (although you do of course have all your code in a
version control system anyway, don't you ...).



=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Manual::Intro>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>,
Andrew Ford, C<A.Ford@ford-mason.co.uk>
Zbigniew Lukasiak, C<zz bb yy@gmail.com> - modifications


=head1 COPYRIGHT

Copyright 2004-2005 Sebastian Riedel. All rights reserved.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
