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
=pod
<select name="newmonth">
  <!--<option value="04">May</option> -->







     <option value="052015">June 2015</option>
    <option value="062015">July 2015</option>
     <option value="072015">August 2015</option>
    <option value="082015">September 2015</option>

    <option value="092015">October 2015</option>
     <option value="102015">November 2015</option>
    <option value="112015">December 2015</option>



      <option value="122015">January 2016</option>


        <option value="012016">February 2016</option>

        <option value="022016">March 2016</option>

        <option value="032016">April 2016</option>

        <option value="042016">May 2016</option>

        <option value="052016">June 2016</option>

          <option value="062016" selected="selected">July 2016</option>
=cut
	return {};
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

method submit_signups(hashRef $input_object)
{
	my $signup_page = $self->_config()->{'signup'};
	my $req = HTTP::Request->new('POST' => $signup_page);

	my $month = $input_object->{'month'};
	my $days  = $input_object->{'days'};

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

method matrix()
{
	my $matrix_page = $self->_config()->{'matrix'};

	# newmonth = "062015" for July 2015
	my $req = HTTP::Request->new('POST' => $matrix_page);

	my $res = $self->_browser()->request($req);

	my $page = $res->content;

	my $month_data = $self->_get_months_from_matrix($page);

	my $signup_info = $self->_get_signup_info_from_matrix($page);

	return $signup_info;
}

1;

