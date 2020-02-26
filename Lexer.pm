package Template::Lexer;

use warnings;
use strict;

use PAL::Lexer;

use Exporter qw(import);
our @EXPORT = qw(lex_template);

my $html_definitions = [
	[qr/^\{\{/, 'LBRACKET', \&t_lbracket],
	[qr/^.+?(?=\{\{|$)/s, 'HTML'],
];

my $tpl_definitions = [
	[qr/^\s+/, 'WHITESPACE', \&t_pass],
	[qr/^\}\}/, 'RBRACKET', \&t_rbracket],
	[qr/^if/, 'IF'],
	[qr/^else/, 'ELSE'],
	[qr/^for/, 'FOR'],
	[qr/^end/, 'END'],
	[qr/^\d+/, 'INTEGER'],
	[qr/^\'[^']+'/, 'STRING', \&t_string],
	[qr/^eq/, 'EQ'],
	[qr/^ne/, 'NE'],
	[qr/^lt/, 'LT'],
	[qr/^le/, 'LE'],
	[qr/^gt/, 'GT'],
	[qr/^ge/, 'GE'],
	[qr/^not/, 'NOT'],
	[qr/^\w+/, 'IDENTIFIER'],
];

sub lex_template
{
	my ($input) = @_;

	return lex($input, $html_definitions);
}

sub t_pass {
	return;
}

sub t_lbracket {
	set_definitions($tpl_definitions);

	return;
}

sub t_rbracket {
	set_definitions($html_definitions);

	return;
}

sub t_string {
	return substr($_[0], 1, -1);
}