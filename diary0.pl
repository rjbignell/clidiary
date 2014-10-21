#!/app/perl5/bin/perl
#

my %projcodes;
my %projnames;
my %activities;
my %acticodes;
my %actinames;
my %projbycode;
my %projbyname;

my $username = $ENV{LOGNAME};
my $todaystr = sprintf("%d-%d-%d",
		    (localtime)[5]+1900,
		    (localtime)[4],
		    (localtime)[3]);

printf("%s-%s.csv\n",$username,$todaystr);

$daydatafile = sprintf("%s-%s.csv\n",$username,$todaystr);
$projectlistfile = "projects.csv";
$activitylistfile = "activities.csv";

read_projects();
read_activities();
display_project_tree();
read_day_so_far();
mainloop();

# ----------------------------------------------------------------

sub mainloop
{
    while (1) {
	display_day_so_far();

	print("What to do - add, quit (a,q): ");
	$cmd = <>;
	chomp($cmd);

	if ($cmd =~ /q/i) {
	    # get out of here
	    return;
	}

	if ($cmd =~ /a/i) {
	    $t = get_a_time();
	    $p = get_a_project();
	    $k = get_a_task($p);
	    printf("t=%s, p=%s, k=%s\n", $t, $p, $k);
	}
    }
}

sub get_a_time
{
    my $eventtime = "";
    my $transtime = "";
    
    $transtime = sprintf("%2.2d:%2.2d",(localtime)[2],(localtime)[1]);

    $eventtime = "";
    while (!length($eventtime)) {
	print("Time of transition ($transtime): ");
	$input = <>;
	chomp($input);
	printf("ilen = %d\n", length($input));
	if (length($input)) {
	    if ($input =~ /^[0-2][0-9]:[0-5][0-9]$/) {
		# time is ok
		$transtime = $input;
		print("ok\n");
		$eventtime = $transtime;
	    }
	    else {
		# time is not ok
		print("Time is not ok, try again.\n");
	    }
	}
	else {
	    # otherwise transtime is already ok
	    $eventtime = $transtime;
	}
    }

    return($eventtime);
}

sub get_a_project
{
    my $eventproject = "";

    while (!length($eventproject)) {
	$num_projects = display_projects();
	print("Enter a project index (or q to quit): ");
	$input = <>;
	chomp($input);
	if ($input =~ /q/i) {
	    return "ABORT";
	}
	unless ($input =~ /^[0-9]+$/) {
	    printf("Your response wasn't a number, try again.\n");
	    next;
	}
	if ($input < 1 || $input > $num_projects) {
	    printf("Out of range, try again.\n");
	    next;
	}
	return($projcodes{$input});
    }
}

sub read_projects
{
    my $index;

    open(PROJECTS, "< $projectlistfile")
	or die "cannot open $projectlistfile for reading: $!\n";

    $index = 1;

    while(<PROJECTS>) {
	chomp;
	($projcode, $projname) = split(/,/);

	$projcodes{$index} = $projcode;
	$projnames{$index} = $projname;

	$index += 1;

	$proj = {
	    CODE => $projcode,
	    NAME => $projname,
	    ACTS => [],
	};
#	print $proj, "n=", ${$proj}{NAME}, "\n";
	$projbyname{ ${$proj}{NAME} } = $proj;
	$projbycode{ ${$proj}{CODE} } = $proj;

#	printf("%s->%s|\n", $projcode, $projname);
    }
    close(PROJECTS);
}

sub display_projects
{
    my $index;

    $index = 1;
    foreach $key (sort keys %projnames) {
	printf("%2d: %s\n", $index, $projnames{$key});
	$index += 1;
    }
    return ($index - 1);
}

sub read_activities
{
    my $index = 1;
    my %act;

    open(ACTIVITIES, "< $activitylistfile")
	or die "cannot open $activitylistfile for reading: $!\n";
    while(<ACTIVITIES>) {
	chomp;
	($projcode, $projname, $acticode, $actiname) = split(/,/);
#	printf("%s->%s->%s->%s|\n", $projcode, $projname, $acticode, $actiname);
	$compoundcode = $projcode . "/" . $acticode;
	$compoundname = $projname . " / " . $actiname;

	$codesary{$index} = $compoundcode;
	$namesary{$index} = $compoundname;
	$magicinverse{$compoundcode} = $compoundname;

	$index += 1;

	$act = {
	    CODE => $acticode,
	    NAME => $actiname,
	};

	$pref = $projbycode{ $projcode };

	push(@{${$pref}{ACTS}},$act);
	
    }
    close(ACTIVITIES);
}

sub get_a_task
{
    my $eventtask = "";
    my $projcode = $_[0];
    my @task_indices = [];

    while (!length($eventtask)) {

	@task_indices = display_project_tasks($projcode);
	$num_tasks = $#task_indices;

	print("Enter a task index (or q to quit): ");
	$input = <>;
	chomp($input);
	if ($input =~ /q/i) {
	    return "ABORT";
	}
	unless ($input =~ /^[0-9]+$/) {
	    printf("Your response wasn't a number, try again.\n");
	    next;
	}
	if ($input < 1 || $input > $num_tasks) {
	    printf("Out of range, try again.\n");
	    next;
	}
	$theindex = $task_indices[$input];
	return($codesary{$theindex});
    }
}

sub display_project_tasks
{
    my $index;
    my $projcode = $_[0];
    my @indices = [];

    $index = 1;
    foreach $key (sort keys %namesary) {
	if ($codesary{$key} =~ /^$projcode\//) {
	    printf("%2d: %s\n", $index, $namesary{$key});
	    $index += 1;
	    push(@indices,$key);
	}
    }
    return(@indices);
}

sub display_project_tree
{
    foreach $key (keys %projbyname) {
	printf("Project: %s, code: %s, tasks:\n",
	       $projbyname{$key}{NAME},
	       $projbyname{$key}{CODE});

	$acref = $projbyname{$key}{ACTS};

	foreach $item (@{$acref}) {
	    printf("Task: %s, code: %s\n", ${$item}{NAME}, ${$item}{CODE});
	}
    }
}

sub read_day_so_far
{
    open(DAYDATA, "< $daydatafile")
	or die "cannot open to read $daydatafile: $!\n";
    while(<DAYDATA>) {
	chomp;
	($timstr,$projcode,$acticode) = split(/,/);
	$daypcodes{$timstr} = $projcode;
	$dayacodes{$timstr} = $acticode;
	$daydata{$timstr} = $projcode . "/" . $acticode;
    }
    close(DAYDATA);
}

sub display_day_so_far
{
    foreach $t (sort keys %daydata) {
	$combo = $daydata{$t};
	printf("At %s started %s (%s)\n", $t, $combo, $magicinverse{$combo});
    }
}
