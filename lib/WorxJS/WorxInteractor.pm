package WorxJS::WorxInteractor;

use File::Slurp qw(read_file);
use JSON qw(from_json);
use LWP::UserAgent;
use Moose;
use Method::Signatures;
use Readonly;

Readonly my $_CONFIG_FILE => q{sites.json};

has _config => (
                 'is'      => 'ro',
                 'isa'     => 'HashRef',
                 'builder' => '_build_config',
                 'lazy'    => 1,
);

has _browser => (
                  'is'      => 'ro',
                  'isa'     => 'LWP::UserAgent',
                  'default' => sub { return LWP::UserAgent->new },
                  'lazy'    => 1,
);

has username => (
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
);

has password => (
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
);

has _user_data => (
                  'is'      => 'ro',
                  'isa'     => 'HashRef',
                  'builder' => '_get_user_data',
                  'lazy'    => 1,
);

method _build_config()
{
	return from_json read_file $_CONFIG_FILE;
}

method _get_user_data()
{
	my $login_data = $self->_config()->{'login_data'};

	my $data = { 'from'     => 'login1',
	             'secure'   => 'go',
	             'username' => $self->username(),
	};

	my $res = $self->_browser()->post($login_data, $data);


	use Data::Printer;

	my @inputs =$res->content =~ /\<input (.*)\/>/g;
	my %data;

	for my $input ( @inputs )
	{
		next unless $input =~ /name="([^"]*)"/;
		my $name = $1;
		next if $name eq 'logon';
		next if $name eq 'from';
		next if $name eq 'pw_entered';
		next if $name eq 'username';
		next unless $input =~ /value="([^"]*)"/;
		my $value = $1;
		$data{$name} = $value;
	}
	$data{'password'} = $data{'pw_in_data'};
	return \%data;
}

method _get_months_from_matrix($page)
{
	my %month_data;
	unless ( $page =~ m#<select name="newmonth">(.*)</select>#s )
	{
		die 'Problem parsing month data from matrix!  Please let Akbar know so he can debug this.';
	}
	$page = $1;
	$page =~ s/\s+/ /sg; # Collapse all whitespace to single spaces, including newlines
	$page =~ s/<!--.*?-->//g;  # Remove HTML comments

	my @month_opts = map {s/^\s+//; s/\s+$//; $_} (split '</option>', $page);

	@month_opts = grep {$_ ne q{}} @month_opts;

	for (@month_opts)
	{
		my ($tag, $val) = split '>';
		push @{$month_data{'months'}}, $val;
		if ($tag =~ /value="([^"]+)"/)
		{
			$month_data{'month_map'}{$val} =  $1;
		}
		if ($tag =~ /selected="selected"/)
		{
			$month_data{'current_month'} = $val;
		}
	}
	return \%month_data;
}


method _get_signup_info_from_matrix($page)
{
	unless ( $page =~ m#(<table width="800".*</table>)#s )
	{
		die 'Problem parsing matrix!  Please let Akbar know so he can debug this.';
	}
	$page = $1;

	$page =~ s#<br\s*/?># #isg; # Remove <br /> tags (turn them to spaces)
	$page =~ s/\s+/ /sg;        # Collapse all whitespace to single spaces, including newlines
	$page =~ s/<p.*?>//g;       # Remove opening <p> tags
	$page =~ s#</p>##g;         # Remove closing </p> tags
	$page =~ s/<div.*?>//g;     # Remove opening <div> tags
	$page =~ s#</div>##g;       # Remove closing </div> tags

	my $useless_tail_columns = 3;
	my $useless_tail_rows    = 7;

	my @rows = map {s/.*<tr.*?>//; $_} (split '</tr>', $page);
	pop @rows for (1..$useless_tail_rows); # Remove the bottom rows we don't care about

	my $header_row = shift @rows; # The header row is always the first row
	my @days = map {s/.*<th.*?>//; s/^\s+//; s/\s+$//; $_} (split '</th>', $header_row);

	pop @days for (1..$useless_tail_columns); # remove the last few columns, we don't care about those

	my $class_field = shift @days; # Get the information on who is a member, etc.
	my @class_entries = map {s/.*<span //; $_} (split '</span>', $class_field);
	my %member_classes;

	for (@class_entries)
	{
		next unless /class="([^"]+)".*?>(.*)/;
		my ($class, $rank) = ($1, $2);
		$rank =~ s/^\s+//;
		$rank =~ s/\s+$//;
		next if $rank eq 'Colors indicate';
		$member_classes{$class} = $rank;
	}

	my %users;

	my $own_user = $self->_user_data()->{'fname'} . q{ } . $self->_user_data()->{'lname'};

	push @days, 'Total';
	 # Currently, we total up signups here (maybe move this to front-end in the future?)

	my %empty_signups = map {$_ => 0} @days;

	my $pretty_level = $self->_user_data()->{'level'};

	for (values %member_classes)
	{
		if ($pretty_level =~ /^$_$/i)
		{
			$pretty_level = $_;
			last;
		}
	}

	# Make sure the logged in user always has a row
	$users{$own_user} = {'member_type' => $pretty_level, 'signups' => \%empty_signups, 'active_user' => 1, 'member' => $own_user};

	for (@rows)
	{
		my @entries = map {s/.*<td.*?>//; s/^\s+//; s/\s+$//; $_} (split '</td>', $_);
		pop @entries for (1..$useless_tail_columns); # remove the last few columns, we don't care about those
		my $name = shift @entries;
		my $class = 'Other';
		if ( $name =~ /class="([^"]+)"/)
		{
			my $class_val = $1;
			$class = $member_classes{$class_val} if exists $member_classes{$class_val};
		}
		$name =~ s#<span.*?>\s*(.*)\s*</span>#$1#;

		my %signups;

		$signups{'Total'} = 0;
		# TODO: Figure out which shows are Harry shows and update that total too
		for (0..$#entries)
		{
			if ( $entries[$_] eq '<strong> X </strong>' )
			{
				$signups{$days[$_]} = 1;
				$signups{'Total'}++;
			}
			else
			{
				$signups{$days[$_]} = 0;
			}
		}

		my $is_active_user = 0;
		$is_active_user = 1 if $own_user eq $name;

		$users{$name} = {'member_type' => $class, 'signups' => \%signups, 'active_user' => $is_active_user, 'member' => $name};
	}

	my @users;
	my $active_idx = -1;
	for (sort keys %users)
	{
		$active_idx = @users if $users{$_}{'active_user'};
		push @users, $users{$_};
	}


	return {'member_classes' => \%member_classes, 'days' => \@days, 'users' => \@users, 'active_idx' => $active_idx};
}

method submit_signups(hashRef :$input!)
{
	my $signup_page = $self->_config()->{'signup'};
	my $req = HTTP::Request->new('POST' => $signup_page);

	my $month = $input->{'month'};
	my $days  = $input->{'days'};

	my %outbound_request = (%{$self->_user_data()}, 'secure' => 'go', 'signups' => ' SAVE Your Sign Ups ');

	#TODO Actually submit useful data?
#	my $res = $self->_browser()->request($req);

=pod
<form id="form3" name="form3" method="post" action="signup2.php">
<input name="showmax" type="hidden" value="25">
<input name="month" type="hidden" value="7">
<input name="year" type="hidden" value="2016">

<input name="dogs1" type="hidden" value="07/01/20168:00 p.m.">
<input name="cats1" type="checkbox" value="yes" checked="checked">

...

<input name="dogs25" type="hidden" value="07/30/201610:00 p.m.">
<input name="cats25" type="checkbox" value="yes"><span class="style2"></span></td>

=cut

	return;
}

method is_password_valid()
{
	return 1 if ($self->password eq $self->_user_data()->{'password'});
	return;
}

method matrix(:$month?)
{
	my $matrix_page = $self->_config()->{'matrix'};

	my $req = HTTP::Request->new('POST' => $matrix_page);
	$req->content_type('application/x-www-form-urlencoded');

	if ( $month ) # If we get a month like "July 2015" we need to pass 062015 in as "newmonth".  Interestingly, January is 12, not 0
	{
		my $idx = 1;
		my %month_map = map {$_ => sprintf('%02d', $idx++)} qw(February March April May June July August September October November December January);

		if ( $month =~ /(\w+)\s+(\d+)/ )
		{
			my ($mon, $year) = ($1, $2);
			my $post_args = 'newmonth=' . $month_map{$mon} . $year
			              . '&submit+month=Chnage+Month';
			$req->content($post_args);
		}
	}

	p $req;
	my $res = $self->_browser()->request($req);

	my $page = $res->content;

	my $month_data = $self->_get_months_from_matrix($page);

	my $signup_info = $self->_get_signup_info_from_matrix($page);

	return {%{$signup_info}, %{$month_data}};
}

1;

