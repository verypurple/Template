package Template::Parser;

use warnings;
use strict;

use PAL::Parser;

use Exporter qw(import); 
our @EXPORT = qw(parse_template parse_stack);

my $grammar = {
	STATEMENT => [
		['HTML'],
		['IDENTIFIER'],
		['IF_STATEMENT'],
		['FOR_STATEMENT'],
	],
	STATEMENTS => [
		['STATEMENT'],
		['STATEMENTS', 'STATEMENT']
	],
	IF_STATEMENT => [
		['IF', 'EXP', 'STATEMENTS', 'END'],
		['IF', 'EXP', 'STATEMENTS', 'ELSE', 'STATEMENTS', 'END'],
	],
	FOR_STATEMENT => [
		['FOR', 'IDENTIFIER', 'STATEMENTS', 'END'],
	],
	EXP => [
		['PRIMITIVE'],
		['UNOP', 'PRIMITIVE'],
		['EXP', 'BINOP', 'EXP'],
	],
	PRIMITIVE => [
		['IDENTIFIER'],
		['STRING'],
		['INTEGER'],
	],
	UNOP => [
		['NOT'],
	],
	BINOP => [
		['EQ'],
		['GT'],
		['GE'],
		['LT'],
		['LE'],
	],
};

my $p_funcs = {
	'STATEMENT : HTML' => \&p_stmt_html,
	'STATEMENT : IDENTIFIER' => \&p_stmt_identifier,
	'PRIMITIVE : IDENTIFIER' => \&p_pmtv_identifier,
	'PRIMITIVE : STRING' => \&p_pmtv_string,
	'PRIMITIVE : INTEGER' => \&p_pmtv_integer,
	'EXP : PRIMITIVE' => \&p_exp_pmtv,
	'EXP : UNOP PRIMITIVE' => \&p_exp_unop,
	'EXP : EXP BINOP EXP' => \&p_exp_binop,
	'IF_STATEMENT : IF EXP STATEMENTS END' => \&p_stmt_if_then,
	'IF_STATEMENT : IF EXP STATEMENTS ELSE STATEMENTS END' => \&p_stmt_if_then_else,
	'FOR_STATEMENT : FOR IDENTIFIER STATEMENTS END' => \&p_stmt_for,
};

sub parse_template
{
	my ($tokens) = @_;

	return parse($grammar, 'STATEMENTS', $tokens, $p_funcs);
}

sub parse_stack
{
	my ($stack, $tokens) = @_;

	return build_ast($stack, $tokens, $p_funcs);
}

sub p_stmt_if_then
{
	return ['if-then', $_[1], $_[2]];
}

sub p_stmt_if_then_else
{
	return ['if-then-else', $_[1], $_[2], $_[4]];
}

sub p_stmt_html
{
	return ['html', $_[0]];
}

sub p_stmt_identifier
{
	return ['identifier', $_[0]];
}

sub p_stmt_for
{
	return ['for', $_[1], $_[2]];
}

sub p_pmtv_identifier
{
	return ['identifier', $_[0]];
}

sub p_pmtv_string
{
	return ['string', $_[0]];
}

sub p_pmtv_integer
{
	return ['integer', $_[0]];
}

sub p_exp_unop
{
	return ['unop', $_[0]->[0], $_[1]];
}

sub p_exp_binop
{
	return ['binop', $_[0], $_[1]->[0], $_[2]];
}

sub p_exp_pmtv
{
	return $_[0];
}

1;
