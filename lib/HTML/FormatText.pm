package HTML::FormatText;

# $Id$

=head1 NAME

HTML::FormatText - Format HTML as text

=head1 SYNOPSIS

 require HTML::FormatText;
 $html = parse_htmlfile("test.html");
 $formatter = new HTML::FormatText;
 print $formatter->format($html);

=head1 DESCRIPTION

The HTML::FormatText is a formatter that outputs plain latin1 text.
All character attributes (bold/italic/underline) are ignored.
Formatting of HTML tables and forms is not implemented.

=head1 SEE ALSO

L<HTML::Formatter>

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no>

=cut

require HTML::Formatter;

@ISA = qw(HTML::Formatter);

use strict;

sub begin
{
    my $self = shift;
    $self->HTML::Formatter::begin;
    $self->{lm}  =    3;  # left margin
    $self->{rm}  =   72;  # right margin (actually, maximum text width)
    $self->{curpos} = 0;  # current output position.
    $self->{maxpos} = 0;  # highest value of $pos (used by header underliner)
    $self->{hspace} = 0;  # horizontal space pending flag
}

sub end
{
    shift->collect("\n");
}


sub header_start
{
    my($self, $level, $node) = @_;
    $self->vspace(1 + (6-$level) * 0.4);
    $self->{maxpos} = 0;
    1;
}

sub header_end
{
    my($self, $level, $node) = @_;
    if ($level <= 2) {
	my $line;
	$line = '=' if $level == 1;
	$line = '-' if $level == 2;
	$self->vspace(0);
	$self->out($line x ($self->{maxpos} - $self->{lm}));
    }
    $self->vspace(1);
    1;
}

sub hr_start
{
    my $self = shift;
    $self->vspace(1);
    $self->out('-' x ($self->{rm} - $self->{lm}));
    $self->vspace(1);
}

sub pre_out
{
    my $self = shift;
    # should really handle bold/italic etc.
    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->nl() while $self->{vspace}-- >= 0;
	    $self->{vspace} = undef;
	}
    }
    my $indent = ' ' x $self->{lm};
    my $pre = shift;
    $pre =~ s/^/$indent/mg;
    $self->collect($pre);
    $self->{out}++;
}

sub out
{
    my $self = shift;
    my $text = shift;

    if ($text =~ /^\s*$/) {
	$self->{hspace} = 1;
	return;
    }

    if (defined $self->{vspace}) {
	if ($self->{out}) {
	    $self->nl while $self->{vspace}-- >= 0;
        }
	$self->goto_lm;
	$self->{vspace} = undef;
	$self->{hspace} = 0;
    }

    if ($self->{hspace}) {
	if ($self->{curpos} + length($text) > $self->{rm}) {
	    # word will not fit on line; do a line break
	    $self->nl;
	    $self->goto_lm;
	} else {
	    # word fits on line; use a space
	    $self->collect(' ');
	    ++$self->{curpos};
	}
	$self->{hspace} = 0;
    }

    $self->collect($text);
    my $pos = $self->{curpos} += length $text;
    $self->{maxpos} = $pos if $self->{maxpos} < $pos;
    $self->{'out'}++;
}

sub goto_lm
{
    my $self = shift;
    my $pos = $self->{curpos};
    my $lm  = $self->{lm};
    if ($pos < $lm) {
	$self->{curpos} = $lm;
	$self->collect(" " x ($lm - $pos));
    }
}

sub nl
{
    my $self = shift;
    $self->{'out'}++;
    $self->{curpos} = 0;
    $self->collect("\n");
}

sub adjust_lm
{
    my $self = shift;
    $self->{lm} += $_[0];
    $self->goto_lm;
}

sub adjust_rm
{
    shift->{rm} += $_[0];
}

1;
