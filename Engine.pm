package Template::Engine;

use warnings;
use strict;

use Template::Lexer;
use Template::Parser;

use Exporter qw(import);
our @EXPORT = qw(render);

my $i_funcs = {
	'if-then' => \&i_stmt_if_then,
	'if-then-else' => \&i_stmt_if_then_else,
	'for' => \&i_stmt_for,
	'html' => \&i_stmt_html,
	'identifier' => \&i_stmt_identifier,
};

my $output;

sub render 
{
	my ($path, $data) = @_;

	$output = '';

	$path =~ m/^(.+?)(\.[^.]+?)?$/m;
	my $cache_path = "$1.ast";

	my $input = read_file($path);
	my $tokens = lex_template($input);

	my $stack;

	if (-e $cache_path) {
		$stack = read_cache($cache_path);
	}
	else {
		$stack = parse_template($tokens);
		write_cache($cache_path, $stack);
	}

	my $tree = parse_stack($stack, $tokens);

	if ($tree) {
		interpret($tree, $data);
		return $output;
	}
	else {
		return "Input is invalid.";
	}
}

sub read_file {
	my ($path) = @_;
	my $data;

	open(my $fh, $path)
		or die "Could not read file '$path'. $!";
	while (my $row = <$fh>) {
		$data .= $row
	}
	close($fh);

	return $data;
}

sub read_cache {
	my ($path) = @_;
	my $stack;

	open(my $fh, $path)
		or die "Could not read file '$path'. $!";
	while (my $row = <$fh>) {
		my $state = [split(',', $row)];
		$state->[1] = [split(' ', $state->[1])];
		push(@$stack, $state);
	}
	close($fh);

	return $stack;
}

sub write_cache {
	my ($path, $data) = @_;

	open(my $fh, ">$path")
		or die "Could not write file '$path'. $!";
	for my $line (@$data) {
		print $fh "$line->[0],@{$line->[1]},$line->[2]\n";
	}
	close($fh);
}

sub interpret
{
	my ($tree, $context) = @_;

	for my $node (@$tree) {
		if (exists($i_funcs->{$node->[0]})) {
			$i_funcs->{$node->[0]}(@$node[1..$#$node], $context);
		}
		else {
			interpret($node, $context);
		}
	}
}

sub evaluate
{
	my ($exp, $context) = @_;

	return ref($context) eq 'HASH'
		&& exists($context->{$exp})
		&& $context->{$exp};
}

sub i_stmt_if_then
{
	my ($condition, $then, $context) = @_;

	i_stmt_if_then_else($condition, $then, [], $context);
}


sub i_stmt_if_then_else
{
	my ($condition, $then, $else, $context) = @_;

	if (evaluate($condition, $context)) {
		interpret($then, $context);
	}
	elsif ($else) {
		interpret($else, $context);
	}
}

sub i_stmt_for
{
	my ($identifier, $stmts, $context) = @_;

	for my $el (@{$context->{$identifier}}) {
		interpret($stmts, $el);
	}
}

sub i_stmt_html
{
	$output .= $_[0];
}

sub i_stmt_identifier
{
	my ($value, $context) = @_;

	if (ref($context) eq 'HASH') {
		if (exists($context->{$value})) {
			$output .= $context->{$value};
		}
	}
	else {
		$output .= $context;
	}
}

1;
