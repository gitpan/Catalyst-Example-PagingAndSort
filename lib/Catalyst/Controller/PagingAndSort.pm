package Catalyst::Controller::PagingAndSort;
use version; $VERSION = qv('0.0.3');
my $LOCATION; 
BEGIN { use File::Spec; $LOCATION = File::Spec->rel2abs(__FILE__) }

use warnings;
use strict;
use Carp;
use base 'Catalyst::Base';
use URI::Escape;
use HTML::Entities;
use Catalyst::Utils;

sub auto : Local {
    my ( $self, $c ) = @_;
    my $viewclass = ref $c->comp('^'.ref($c).'::(V|View)::');
    no strict 'refs';
    my $root   = $c->config->{root};
    my $libroot = $LOCATION;
    $libroot =~ s{\.pm$}{/templates};     # tofix
    my @additional_paths = ("$root/PagingAndSort/" . $self->Table_name, "$root/PagingAndSort", $libroot);
    $c->stash->{additional_template_paths} = \@additional_paths;
    $c->stash->{table_name} = lc $self->Table_name();
    $c->stash->{table_class} = $self->Table_Class();
}

sub Table_name {
    my $self = shift;
    my $class = ref $self;
    $class =~ /([^:]*$)/;
    return $1;
}

sub Table_Class {
    my $self = shift;
    my $class = ref $self;
    return Catalyst::Utils::class2appclass($class) . '::Model::CDBI::' .  $self->Table_name();
}

sub add : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'add.tt';
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

sub destroy : Local {
    my ( $self, $c, $id ) = @_;
    my $table_class = $self->Table_Class();
    $table_class->retrieve($id)->delete;
    $c->forward('list');
}

sub do_add : Local {
    my ( $self, $c ) = @_;
    my $table_class = $self->Table_Class();
    $c->form( optional => [ $table_class->columns ] );
    $table_class->create_from_form( $c->form );
    $c->forward('list');
}


sub do_edit : Local {
    my ( $self, $c, $id ) = @_;
    my $table_class = $self->Table_Class();
    $c->form( optional => [ $table_class->columns ] );
    $table_class->retrieve($id)->update_from_form( $c->form );
    $c->forward('list');
}

sub edit : Local {
    my ( $self, $c, $id ) = @_;
    my $table_class = $self->Table_Class();
    $c->stash->{item} = $table_class->retrieve($id);
    $c->stash->{template} = 'edit.tt';
}


sub create_page_link {
    my ( $c, $page, $params, $table ) = @_;
    $params->{page} = $page;
    my $addr;
    for my $key (keys %$params){
        $addr .= "&$key=" . $params->{$key};
    }
    $addr = uri_escape($addr, q{^;/?:@&=+\$,A-Za-z0-9\-_.!~*'()} );
    $addr = encode_entities($addr, '<>&"');
    my $result = '<a href="' . $c->req->{base} . $table . '/list?';
    $result .= $addr . '">' . $page . '</a>';
    return $result;
}

sub create_col_link {
    my ( $c, $column, $params, $table ) = @_;
    if(($params->{order} eq $column) and !$params->{o2}){
        $params->{o2} = 'desc';
    }else{
        delete $params->{o2};
    }
    $params->{order} = $column;
    delete $params->{page};        # just in case you'll use paging sometime
    my $addr;
    for my $key (keys %$params){
        $addr .= "&$key=" . $params->{$key};
    }
    $addr = uri_escape($addr, q{^;/?:@&=+\$,A-Za-z0-9\-_.!~*'()} );
    $addr = encode_entities($addr, '<>&"');
    my $result = '<a href="' . $c->req->{base} . $table . '/list?';
    $result .= $addr . '">' . $column . '</a>';
    if($column eq $c->form->valid->{order}){
        if($c->form->valid->{o2}){
            $result .= "&darr;";
        }else{
            $result .= "&uarr;";
        }
    }
    return $result;
}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->form( optional => [ qw/order o2 page/ ] );
    $c->stash->{valid} = $c->form->valid;
    my $order = $c->form->valid->{order};
    $order .= ' DESC' if $c->form->valid->{o2};
    my $maxrows = 10;
    my $offset = ($c->form->valid->{page} - 1) * $maxrows;
    my $table_class = $self->Table_Class();
    $c->stash->{objects} = [
        $table_class->retrieve_all(
#            { id => => { '!=', undef }},
            { order_by => $order,
              rows => $maxrows,
              offset => $offset },
        ) ];
    my $count = $table_class->count();
    $c->stash->{pages} = int($count / $maxrows) + 1;
    $c->stash->{order_by_column_link} = sub {
        my $column = shift;
        my %params = %{$c->form->valid};
        return create_col_link($c, $column, \%params, lc $self->Table_name() );
    };
    $c->stash->{page_link} = sub {
        my $page = shift;
        my %params = %{$c->form->valid};
        return create_page_link($c, $page, \%params, lc $self->Table_name() );
    };
    $c->stash->{template} = 'list.tt';
}

sub view : Local {
    my ( $self, $c, $id ) = @_;
    my $table_class = $self->Table_Class();
    $c->stash->{item} = $table_class->retrieve($id);
    $c->stash->{template} = 'view.tt';
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Catalyst::Controller::PagingAndSort - Catalyst CRUD example Controller


=head1 VERSION

This document describes Catalyst::Controller::PagingAndSort version 0.0.1


=head1 SYNOPSIS

    use base Catalyst::Controller::PagingAndSort;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 METHODS

=over 4

=item Table_Class
Class method for finding corresponding CDBI model class.

=item Table_name
Class method for finding name of corresponding database table.

=item auto
This automatically called method puts on the stash path to templates
distributed with this module

=item add
Method for displaying form for adding new records

=item create_col_link
Subroutine placed on stash for templates to use.

=item create_page_link
Subroutine placed on stash for templates to use.

=item default
Forwards to list

=item destroy
Deleting records.

=item do_add
Method for adding new records

=item do_edit
Method for editin existing records

=item edit
Method for displaying form for editing a record.

=item list
Method for displaying pages of records

=item view
Method for diplaying one record

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Catalyst::Controller::PagingAndSort requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-controller-pagingandsort@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

<Zbigniew Lukasiak>  C<< <<zz bb yy @ gmail.com>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, <Zbigniew Lukasiak> C<< <<zz bb yy @ gmail.com>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
