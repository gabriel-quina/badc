#!/usr/bin/perl 


require "config.pl";
require "cgi-lib.pl";
use IO::Handle;   # because autoflush
use DBI();

$PAR_VERSION="2.0";
# db stuff global declaration
@row=();
$dbh="";
$sth="";

sub distance ($$$$);
sub get_name($);
sub get_task($);
sub get_plane($);
sub get_base_AF($);
sub get_report_nbr();
sub get_segundos($);
sub army_of_coordinates($$);
sub dist_to_friend_fm($$$);
sub duracion_mision();
sub build_pilot_list();
sub update_exp();
sub get_task_perc_sorvive($$);
sub bytask_sourvive_list();
sub find_safe_pilots();
sub find_PKilled_pilots();
sub get_pilot_exp($);
sub get_pilot_fairp($);
sub get_akill_points($$);
sub get_gkill_points($$);
sub get_mis_result_points($$);
sub detect_massive_disco();
sub search_for_rescuer($$$$$$);
sub print_pilot_actions();
sub eventos_aire();
sub eventos_tierra();
sub read_mis_details();
sub print_mis_objetive_result();
sub look_af_and_ct();
sub look_resuply();
sub look_sectors();
sub check_geo_file();
sub check_sec_sumin();
sub check_day();
sub draw_1pix ($$$$$);
sub draw_octants ($$$$$$$);
sub draw_circle ($$$$);
sub make_image();
sub make_attack_page();

sub distance ($$$$) {
    my ($x1,$y1,$x2,$y2)=@_;
    return (sqrt(($x1-$x2)**2+($y1-$y2)**2));
}


# param pilot code 
sub get_task($){
    my $code = shift (@_);


  if ($code =~ m/landscape/){
	return("");
    }
    
    if ($code =~ m/crashed/){ # caso especial para eventos aire
	return("");
    }
    if ($code =~ m/NONAME/){ # aveces aparece en los logs los NONAME (vef2 11472)
	return("");
    }

    if ($code =~ m/_para_/){ # aveces aparece en los logs los _para_ (vef2 11597)
	return("");
    }
    if ($code =~ m/_paraplayer_/){ # aveces aparece en los logs los _para_ (vef2 13463)
	return("");
    }
    if ($code =~ m/Static/){
	return("");
    }
    if ($code =~ m/Chief/){
	return("Gnd");
    }

    chop ($code);

    seek DET, 0, 0;
    while(<DET>) {          #I,r0101,2,0,2,air.YAK_1B,100,6rs82,2500,400,Yak-1B,    
	if ($_ =~ m/([^,]+),$code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,/){
	    return ("$1");
	    last;
	}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: get_task() Unknow task  for code $code \n";
    $warnings++;
    return ("-");
}



sub get_plane($){
    my $code = shift (@_);
    my $army=9; # init to unknow

    if ($code =~ m/landscape/){
	return("Accident",8); # 8 = no army
    }
    
    if ($code =~ m/crashed/){ # caso especial para eventos aire
	return("Accident",8);
    }
    if ($code =~ m/NONAME/){ # aveces aparece en los logs los NONAME (vef2 11472)
	return("NOPLANE",8);
    }

    if ($code =~ m/Bridge/){ # puente
	return("Bridge",8); # 8 = no army
    }

    if ($code =~ m/_para_/){ # aveces aparece en los logs los _para_ (vef2 11597)
	return("NOPLANE",8);
    }
    if ($code =~ m/_paraplayer_/){ # aveces aparece en los logs los _para_ (vef2 13463)
	return("NOPLANE",8);
    }



    if ($code =~ m/Static/){
	seek MIS,0,0;
	while(<MIS>) {
	    if ($_ =~ m/$code [^\$ ]+\$([^ ]+) ([12])/){
		return($1,$2); # obj name, army
		last;
	    }
	}
    }
    
    if ($code =~ m/([0-9]+_Chief)[0-9]+/){
	$code=$1;
	seek MIS,0,0;
	while(<MIS>) { #  0_Chief Armor.3-T34 1
	    if ($_ =~ m/$code [^\.]+\.([^ ]+) ([12])/){
		return ($1,$2); # tipo, army
		last;
	    }
	}
    }

    if ($code =~ m/\(/) {
	$code =~ s/(.*)\([0-9]\)/$1/;
    }
    chop($code);
    seek DET, 0, 0;
    while(<DET>) {          #I,r0101,2,0,2,air.YAK_1B,100,6rs82,2500,400,Yak-1B,army,    
	if ($_ =~ m/[^,]+,$code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([^,]+),([12]),/){
	    return ("$1",$2); #external plane name, army
	    last;
	}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: get_plane()  Unknow plane and army of  $code (choped) \n";
    $warnings++;
    return ("-",9); # army unknown
}

sub get_name($){
    my $code = shift (@_);
    my $i;
    my $name="Unknow ai";
    my $army="9"; #init to unknow

    if ($code =~ m/landscape/){
	return("-",8); # 8 = no army
    }

    if ($code =~ m/crashed/){ # caso especial para eventos aire
	return("-",8);
    }

    if ($code =~ m/NONAME/){ # aveces aparece en los logs los NONAME (vef2 11472)
	return("NONAME",8);
    }

    if ($code =~ m/_para_/){ # aveces aparece en los logs los _para_ (vef2 11597)
	return("Para",8);
    }

    if ($code =~ m/_paraplayer_/){ # aveces aparece en los logs los _para_ (vef2 13463)
	return("Paraplayer",8);
    }

    if ($code =~ m/Bridge/){ # puente
	return("Bridge",8); # 8 = no army
    }

   if ($code =~ m/Static/){
	seek MIS,0,0;
	while(<MIS>) {
	    if ($_ =~ m/$code [^\$ ]+\$([^ ]+) ([12])/){
		return("-",$2); # obj name, army
		last;
	    }
	}
    }

    if ($code =~ m/([0-9]+_Chief)[0-9]+/){
	$code=$1;
	seek MIS,0,0;
	while(<MIS>) { #  0_Chief Armor.3-T34 1
	    if ($_ =~ m/$code [^\.]+\.([^ ]+) ([12])/){
		return ("-",$2); # tipo, army
		last;
	    }
	}
    }



    #nso fijamos si es un humano  puede ser un humano
    for ( $i=0; $i<$hpilots; $i++){
	if ($code eq $pilot_list[$i][1] || $code eq $pilot_list[$i][2]) {
	    return($pilot_list[$i][0],$pilot_list[$i][5]); #hlname, army
	    last;
	}
    }

    #si tampoco es un humano puede ser un ai:
    if ($code =~ m/\(/) {
	$code =~ s/(.*)\([0-9]\)/$1/;
    }
    chop($code);
    seek DET, 0, 0;
    while(<DET>) {          #I,r0101,2,0,2,air.YAK_1B,100,6rs82,2500,400,Yak-1B,army,
	if ($_ =~ m/[^,]+,$code,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([12]),/){
	    if ($1==0) {return ("AI Rookie",$2)};
	    if ($1==1) {return ("AI Normal",$2)};
	    if ($1==2) {return ("AI Veteran",$2)};
	    if ($1==3) {return ("AI Ace",$2)};
	    last;
	}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: get_name() Unknow plane and army of  $code (choped) \n";
    $warnings++;

    return ("-",9); # retorna - si no encontro un nombre, 0= army unknow
}


#obtener y retornar  el codigo de la base donde partio el piloto.
sub get_base_AF($){
    my $code = shift @_;
    
    if ($code =~ m/\(/) {
	$code =~ s/(.*)\([0-9]\)/$1/;
    }
    chop($code);
    seek MIS,0,0;
    while(<MIS>) {
	if ($_ =~ m/\[$code.Way\]/){
	    while(<MIS>) {
		if ($_ =~ m/(TAKEOFF) ([^ ]+) ([^ ]+)/){
		    $tocx=$2;
		    $tocy=$3;
		    last;
		}
	    }
	    last;
	}
    }
    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) { 
	if ($_ =~ m/(AF[0-9]{2}),[^,]+,([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+:[12]/) {
	    if (distance($tocx,$tocy,$2,$3)<2000){
		return ("$1");
	    }
	}
    }
    return ("");
}



## obtener un numero de mision unico, verificando que ningun proceso paralelo moleste
## windows problema: flock() unimplemented on this platform
sub get_report_nbr(){

    my $extend="_";
    my $counter;
    my $ret=0;
    
    if (!(open (COU,"<rep_counter.data"))){
	print "$big_red ERROR: Can't open report counter file : $! (read)<br>\n";
	print "Please NOTIFY this error.\n";
	unlink $parser_lock;
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open report counter file : $!\n\n";
	exit(0);
    }

    $counter=<COU>;
    close(COU);
    
    if (!(open (COU,">rep_counter.data"))){
	print "$big_red ERROR:  Can't open report counter file : $! (update)<br>\n";
	print "Please NOTIFY this error.\n";
	unlink $parser_lock;
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open report counter file : $!\n\n";
	exit(0);
    }
    $extend=$counter;
    $counter =~ s/_//;
    printf COU ("_%05.0f",$counter+1);
    close(COU);
    return($extend); ## retorna:   _%05.0f
}

sub get_segundos($){
    my $hms = shift(@_);
    my $seg=0;

    $hms =~ m/([0-9]+):([0-9]+):([0-9]+)/;
    $seg=$1*3600+$2*60+$3;
    return ($seg);
}

sub army_of_coordinates($$){
    my $x = shift(@_);
    my $y = shift(@_);
    my $dist=500001;
    my $near=500000;
    my $army=0;
    seek MIS,0,0;
    while(<MIS>) {
	if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([12])/){
	    $dist=distance($x,$y,$1,$2);
	    if ($dist<$near){
		$near=$dist;
		$army=$3;
	    }
	}
    }
    return($army);
}

sub dist_to_friend_fm($$$){
    my ($x,$y,$army) = (@_);
    my $dist=500001;
    my $near=500000;
    seek MIS,0,0;
    while(<MIS>) {
	if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) $army/){
	    $dist=distance($x,$y,$1,$2);
	    if ($dist<$near){
		$near=$dist;
	    }
	}
    }
    return (int($near/1000));  # retun rounded distance in KM
}

sub duracion_mision(){
    my $g_seg=0;
    my $s_seg=0;
    my $e_seg=0;
    my $l_seg=0;
    my $last_time_str=0;
    my $beg=0;
    my $end=0;
    $stime_str="NOT SET"; 
    $etime_str="NOT SET"; 
    seek LOG, 0, 0;
    while(<LOG>) {
if ( $_ =~ m/(([0-9]+):([0-9]+):([0-9]+)) Mission BEGIN/){
	    $stime_str=$1;
	    $s_seg=$2*3600+$3*60+$4;
	    $beg=1;
	}
	if (!$beg && $_ =~ m/(([0-9]+):([0-9]+):([0-9]+)) [^ ]+ is trying to occupy seat/){
	    $stime_str=$1;
	    $s_seg=$2*3600+$3*60+$4;
	}
	if ( $_ =~ m/(([0-9]+):([0-9]+):([0-9]+)) Mission END/){
	    $etime_str=$1;
	    $e_seg=$2*3600+$3*60+$4;
	    $end=1;
	}
	if ( $_ =~ m/(([0-9]+):([0-9]+):([0-9]+))/){
	    $last_time_str=$1;
	    $l_seg=$2*3600+$3*60+$4;
	}
    }

    if(!$beg){
	print PAR_LOG " $MIS_TO_REP WARNING: Mission BEGIN line NOT FOUND.\n";
	$warnings++;
    }
    if(!$end){
	print PAR_LOG " $MIS_TO_REP WARNING: Mission END line NOT FOUND. Using last event\n";
	$etime_str=$last_time_str;
	$e_seg=$l_seg;
	$warnings++;
    }

    if ($stime_str eq "NOT SET" || $etime_str eq "NOT SET") {
	if ($stime_str eq "NOT SET") {
	    print PAR_LOG " $MIS_TO_REP  WARNING: Fatal : cant set Starting mission time \n";
	    $warnings++;
	}
	
	if ($etime_str eq "NOT SET") {
	    print PAR_LOG " $MIS_TO_REP WARNING: Fatal : cant set Ending mission time \n";
	    $warnings++;
	}
	return;
    }

    # verificacion de congruencia de tiempo
    seek MIS, 0, 0;
    while(<MIS>) {
	if ( $_ =~ m/TIME ([0-9]+\.[0-9]+)/) {
	    $g_seg=$1*3600;
	    if (abs($g_seg-$s_seg) > 2){ 
		print PAR_LOG " $MIS_TO_REP WARNING: TIME diff: ". abs($g_seg-$s_seg)." \n";
		$warnings++;
	    }
	    last;
	}
    }
}



sub build_pilot_list(){
    my $plane="";
    my $pilot="";
    my $seat="";
    my $wing="";
    my $army=0;
    my $task="";
    my $ic;
    my $add;
    my $experience=0.9; # dafault to 0.9 (despues actualizado en sub update_exp();)
    my $banned_count=0;
    seek LOG, 0, 0;
    while(<LOG>) {
	if ($_ =~ m/$stime_str ([^ ]+) seat occupied by (.*) at [0-9]+/) {
	    $plane=$1;
	    $seat=$1;
	    $pilot=$1;
	    $hlname=$2;
	    $add=1; # agregar el piloto por default
	    if ($hlname =~ /\\/) {next;} # \ char not allowed in hlname (DB problems, php and so on)
##

	    $sth = $dbh->prepare("SELECT COUNT(*) FROM $pilot_file_tbl WHERE hlname=?");
	    $sth->execute($hlname);
	    @row = $sth->fetchrow_array;
	    $sth->finish;
	    if ($row[0]==1) { #pilot exist on pilot_file 
		$sth = $dbh->prepare("SELECT banned FROM $pilot_file_tbl WHERE hlname=?");
		$sth->execute($hlname);
		@row = $sth->fetchrow_array;
		$sth->finish;
		if ($row[0]==1) { #pilot is banned
		    $banned_count++; # to avoid repetitions in case more than one banned in mission.
		    print PAR_LOG " $MIS_TO_REP $hlname. name changed to Banned_player".$banned_count."\n";
		    $warnings++;
		    $hlname="Banned_player".$banned_count;
		}
	    }
	    else {  # pilot is not in DB
		if ($ALLOW_AUTO_REGISTER==0) {next;} # no auto register, pilot will be counted as an AI
	    }

	    my $line_back=tell LOG; # pos del log
	    while(<LOG>) { # 15:18:36 GA_Gerko has disconnected
		if ($_ =~ m/$stime_str ([^ ]+) has disconnected/) {
		    if ($1 eq $hlname) {# count down disco ?
			$add=0;
			print PAR_LOG " $MIS_TO_REP $hlname disco after hit fly. Disco in countdown\n";
			$warnings++;
		    } 
		}
	    }
	    seek LOG,$line_back,0; # regresamos 

	    for ($ic=0; $ic<$hpilots; $ic++){
		if ($pilot_list[$ic][0] eq $hlname) {$add=0;} # ya estaba en la lista
	    }
	    if ($add){
		$plane =~ s/(.*)\([0-9]+\)/$1/;
		$pilot =~ s/.*\(([0-9]+)\)/$1/;
		$wing =$plane;
		$pos =chop($wing);
		if ($pos eq "0") {$pos="Leader";}
		if ($pos eq "1") {$pos="Wingman 1";}
		if ($pos eq "2") {$pos="Wingman 2";}
		if ($pos eq "3") {$pos="Wingman 3";}
		seek DET, 0, 0;
		while(<DET>) {          #I,r0101,2,0,2,air.YAK_1B,100,6rs82,2500,400,Yak-1B,army
		    if ($_ =~ m/([^,]+),$wing,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([^,]+)/){
			$task=$1;
			$army=$2;
			last;
		    }
		}
		if ($pilot) {$pos="$pos (Gunn $pilot)"; $task="ART";} # si el campo piloto no es 0 es arillero.

		if ($task eq "SUM"){
		    my $line_back=tell LOG; # pos del log
		    while(<LOG>) { # 15:18:36 GA_Gerko has disconnected
			if ($_=~  m/$stime_str $plane loaded weapons \'([^ ]+)\' fuel ([0-9%]+)/){
			    my $weapons=$1;
			    my $fuel=$2;
			    if ($fuel ne "100%" || $weapons ne "default") { 
			    #if ($weapons ne "default") { 
				# es SUM, pero no cargo 100 fuel ni default weapons -> lo pasamos a BA
				$task="BA";
			    }
			    last;
			}
		    }
		    seek LOG,$line_back,0; # regresamos 
		}
		push (@pilot_list,[$hlname,$plane,$seat,$pos,$wing,$army,$task,$experience]);
		$hpilots++;
	    }
	}
      SKIP:
    }

#    for ($i=0 ; $i<$hpilots; $i++){ # lista inicial
#	print $pilot_list[$i][2]."\n";
#    }

    my @temp=();
    my $i;
    my $j;
    for ($i=0 ; $i<$hpilots-1; $i++){
	for ($j=$i+1 ; $j<$hpilots; $j++){
	    if ($pilot_list[$i][2] gt $pilot_list[$j][2]){
		@temp=($pilot_list[$i][0],$pilot_list[$i][1],$pilot_list[$i][2],
		       $pilot_list[$i][3],$pilot_list[$i][4],$pilot_list[$i][5],$pilot_list[$i][6],,$pilot_list[$i][7]);
		$pilot_list[$i]=[$pilot_list[$j][0],$pilot_list[$j][1],$pilot_list[$j][2],
				 $pilot_list[$j][3],$pilot_list[$j][4],$pilot_list[$j][5],
				 $pilot_list[$j][6],,$pilot_list[$j][7]];
		$pilot_list[$j]= [@temp];
	    }
	}
    }
#    print "---------------------\n"; # lista ordenada
#    for ($i=0 ; $i<$hpilots; $i++){
#	print $pilot_list[$i][2]."\n";
#    }

}

# esto coloca los valores de experiencia PREVIOS a la mision en la lista de pilotos
# asi luego get_pilot_exp puede consultar los valores anteriores de pilotos ya procesados
#
sub update_exp(){

    my $i;
    my $name;
    for ($i=0 ; $i<$hpilots; $i++){
	$name = $pilot_list[$i][0]; # regex hlname?
	$sth = $dbh->prepare("SELECT COUNT(*) FROM $pilot_file_tbl WHERE hlname=?");
	$sth->execute($name);
	@row = $sth->fetchrow_array;
	$sth->finish;
	if ($row[0]>0) { #piloto existe
	    $sth = $dbh->prepare("SELECT experience FROM $pilot_file_tbl WHERE hlname=?");
	    $sth->execute($name);
	    @row = $sth->fetchrow_array;
	    $sth->finish;
	    $pilot_list[$i][7]=$row[0];
	}
    }
}


# param:  army, task
sub get_task_perc_sorvive($$){
    my $army = shift @_;
    my $task = shift @_;
    my $total_in_task=0;
    my $total_destroyed=0;

    for ($i=0 ; $i<$task_groups; $i++){
	if ($army eq  $task_planes_list[$i][0]) {
	    if ($task eq  $task_planes_list[$i][1]) {
		$total_in_task+=$task_planes_list[$i][3];
		$total_destroyed+=$task_planes_list[$i][4];
	    }
	}
    }
#    print "army $army task $task sourvive %". (int((1-($total_destroyed/$total_in_task))*100))."\n";
    if ($total_in_task){
	return (int((1-($total_destroyed/$total_in_task))*100));
    }
    else {
	return (0);
    }
}


sub bytask_sourvive_list(){

    seek DET, 0, 0;
    while(<DET>) {
	# BD,34BAP00,4,0,2,air.IL_2Type3,100,4xBRS132,1000,350,IL-2 1943 23mm,1,
	if ($_ =~ m/([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,air[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([^,]+),/){
	    push (@task_planes_list,[$4,$1,$2,$3,0]); # army, task, flight_code, plane nbr, destroyed 
	    $task_groups++;
	}
    }
    
    seek LOG, 0, 0;
    while(<LOG>) {
	if ($_=~  m/([^ ]+) ([^ ]+) shot down by [^ ]+ at /){ 
	    my $vale=1;
	    my $nocuenta;
	    foreach $nocuenta (@PKilled_pilots) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    if ($vale){ 
		my $code=$2;
		chop($code);
		for ($i=0 ; $i<$task_groups; $i++){
		    if ($code eq  $task_planes_list[$i][2]) {
			$task_planes_list[$i][4]++;
			last;
		    }
		}
	    }
	}
	if ($_=~  m/([^ ]+) ([^ ]+) crashed at /){ 
	    my $vale=1;
	    my $nocuenta;
	    foreach $nocuenta (@PKilled_pilots) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    if ($vale){ 
		my $code=$2;
		chop($code);
		for ($i=0 ; $i<$task_groups; $i++){
		    if ($code eq  $task_planes_list[$i][2]) {
			$task_planes_list[$i][4]++;
			last;
		    }
		}
	    }
	}
	if ($_=~  m/([^ ]+) ([^ ]+)\(0\) was killed by [^ ]+ at/){
	    my $code=$2;
	    chop($code);
	    for ($i=0 ; $i<$task_groups; $i++){
		if ($code eq  $task_planes_list[$i][2]) {
		    $task_planes_list[$i][4]++;
		    last;
		}
	    }
	}
    }
    #for ($i=0 ; $i<$task_groups; $i++){
    #    print $task_planes_list[$i][0]." \t".
    #	  $task_planes_list[$i][1]." \t".
    #	  $task_planes_list[$i][2]." \t".
    #	  $task_planes_list[$i][3]." \t".
    #	  $task_planes_list[$i][4]." \n";
    #}
}


sub find_safe_pilots(){
    @land_in_base=();
    @last_land_in_base=();
    seek LOG, 0, 0;
    while(<LOG>) {		
	if  ($_=~  m/([^ ]+) ([^ ]+) landed at ([^ ]+) ([^ ]+)/ ){
	    my $ltime=$1;
	    my $plane=$2;
	    my $lcx=$3;
	    my $lcy=$4;
	    my $army=0;
	    my $hlname="";
	    my $seat="";

	    # detectamos un landing, por lo que eliminamos sunombre de last_land_in_base.
	    foreach my $code (@last_land_in_base) { 
		if ($code eq $plane) { 
		    my $temp;
		    while(1){
			$temp = shift (@last_land_in_base);
			if ($temp eq $plane) {
			    last;
			}
			else {
			    push(@last_land_in_base,$temp);
			}
		    }
		    last;
		}
	    }

	    for (my $i=0 ; $i<$hpilots; $i++){ # lista inicial
		if ($pilot_list[$i][1] eq $plane){
		    $army= $pilot_list[$i][5];
		    $hlname = $pilot_list[$i][0];
		    $seat = $pilot_list[$i][2];
		    $seat =~ s/.*\(([0-9]+)\)/$1/;  # seat ahora contieene solo 0 o 1 ...
		}
	    }
	    if ($army>0) { # si army ha quedado seteado
		seek GEO_OBJ, 0, 0;
		while(<GEO_OBJ>) {
		    #AF02,aerodromo--C12,22007.76,115196.71,2,-C,12,2,95:2
		    if ($_ =~ m/^AF[0-9]{2},[^,]+,([^,]+),([^,]+),[^:]+:[12]/){    # si es AF 
			my $afcx=$1;
			my $afcy=$2;
			if (distance($lcx, $lcy, $afcx, $afcy)<2000){               # si aterriza a menso de 2km	    
			    # determinamos el afarmy con datos de la MISION (no de frontline)
			    my $near=500000; # gran distancia para empezar
			    my $afarmy=0;
			    seek MIS,0,0;
			    while(<MIS>) {
				if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([12])/){
				    $dist=distance($afcx,$afcy,$1,$2);
				    if ($dist>=0 && $dist<$near){
					$near=$dist;
					$afarmy=$3;
				    }
				}
			    }
			    if ($afarmy == $army) { # si aterrizo en base amiga
				my $vale=1;  # por defecto vale : el pilot esta a salvo, last land in base, land in base+1
				push(@land_in_base, $plane);      # aceptamos un aterrizaje en base

				my $regex_hlname=$hlname;
				$regex_hlname =~ s/\\/\\\\/g; #algunos nombres son incompatibles con regex \
				$regex_hlname =~ s/\//\\\//g; #algunos nombres son incompatibles con regex /
				$regex_hlname =~ s/\|/\\\|/g; #algunos nombres son incompatibles con regex |
				$regex_hlname =~ s/\*/\\\*/g; #algunos nombres son incompatibles con regex *
				$regex_hlname =~ s/\(/\\\(/g; #algunos nombres son incompatibles con regex )
				$regex_hlname =~ s/\)/\\\)/g; #algunos nombres son incompatibles con regex (
				$regex_hlname =~ s/\+/\\\+/g; #algunos nombres son incompatibles con regex +
				$regex_hlname =~ s/\[/\\\[/g; #algunos nombres son incompatibles con regex [
				$regex_hlname =~ s/\]/\\\]/g; #algunos nombres son incompatibles con regex ]
				$regex_hlname =~ s/\'/\\\'/g; #algunos nombres son incompatibles con regex '
				$regex_hlname =~ s/\?/\\\?/g; #algunos nombres son incompatibles con regex ?

				my $line_back=tell LOG; # pos del log
				seek LOG, 0, 0;
				while (<LOG>){ # buscamos si es derribado
				    if ($_=~  m/[^ ]+ $plane shot down by [^ ]+ at ([^ ]+) ([^ ]+)/){
					if (distance($lcx, $lcy, $1, $2)>2000){  # si fue destruido lejos
					    $vale=0;
					}
				    }
				    if ($_=~  m/[^ ]+ $plane\($seat\) was killed / ||
					$_=~  m/[^ ]+ $plane\($seat\) has chute destroyed/ ){ # buscamos que no este muerto
					$vale=0;
				    }
				}
				if ($vale) {
				    push(@last_land_in_base, $plane); # aceptamos ultimo aterrizaje en base
				}
				seek LOG,$line_back,0; # regresamos 
			    }
			}
		    }
		}
	    }
	}
    }
    #debug sacar
    #print "Pilotos que no contaran como derribados:\n";
    #foreach my $in (@last_land_in_base){
    #    my ($by,$by_army)=get_name($in);
    #    print "$by \n";
    #}
    #debug sacar
    #print "Pilotos que  aterrizaron en base:\n";
    #foreach my $in (@land_in_base){
    #    my ($by,$by_army)=get_name($in);
    #    print "$by \n";
    #}
}




sub find_PKilled_pilots(){
    @PKilled_pilots=();
    seek LOG, 0, 0;
    while(<LOG>) {		
	if ($_=~  m/[^ ]+ ([^ ]+)\(0\) was killed by ([^ ]+) at [^ ]+ [^ ]+/){ # piloto muerto
	    if ($1 ne $2){ # si no se mato asimismo.
		push(@PKilled_pilots,$1);
	    }
	}
    }
}


sub get_pilot_exp($){
    my $name = shift @_;
    my $exp =1; # def to 1

    if ($name eq "AI Rookie"){
	$exp=0.6; return($exp);
    }
    if ($name eq "AI Normal"){
	$exp=0.7; return($exp);
    }
    if ($name eq "AI Veteran"){
	$exp=0.8; return($exp);
    }
    if ($name eq "AI Ace"){
	$exp=1; return($exp);
    }

    for ($i=0 ; $i<$hpilots; $i++){
	if ( $pilot_list[$i][0] eq $name) {
	    return($pilot_list[$i][7]);
	}
    }
    print PAR_LOG " $MIS_TO_REP WARNING: Returning default experience for name : $name\n";
    $warnings++;
    return($exp); # new pilot or not found
}


sub get_pilot_fairp($){
    my $name = shift @_;
    my $fairp =100; # def to 100

    if ($name =~ m/AI /){
	$fairp=100; return($fairp);
    }

    $sth = $dbh->prepare("SELECT COUNT(*) FROM $pilot_file_tbl WHERE hlname=?");
    $sth->execute($name);
    @row = $sth->fetchrow_array;
    $sth->finish;
    if ($row[0]>0) { #piloto existe
	$sth = $dbh->prepare("SELECT fairplay FROM $pilot_file_tbl WHERE hlname=?");
	$sth->execute($name);
	@row = $sth->fetchrow_array;
	$sth->finish;
	$fairp=$row[0];
	return($fairp)
    }
    return($fairp) # new pilot or not found
}


# killer_code killed_code
sub get_akill_points($$){
    my $killer_code = shift @_;
    my $killed_code = shift @_;
    my ($killer_name,$unused_army1)=get_name($killer_code);
    my ($killed_name,$unused_army2)=get_name($killed_code);
    my $killer_task=get_task($killer_code);
    my $killed_task=get_task($killed_code);

    if ($killer_task eq "BA"  || $killer_task eq "BD" || $killer_task eq "SUM") {
	if ($killed_task eq "I" || $killed_task eq "ET" || $killed_task eq "ER" || 
	    $killed_task eq "EBD" || $killed_task eq "EBA" || $killed_task eq "ESU"){
	    return (6); # era 4
	}
	else {
	    return (0); # era 0
	}
    }

    if ($killer_task eq "ET"  || $killer_task eq "I") {
	if ($killed_task eq "BD" || $killed_task eq "BA" || $killed_task eq "SUM"){
	    return (12); # era 8 
	}
	elsif ($killed_task eq "I" || $killed_task eq "ET" || $killed_task eq "ESU" || 
	       $killed_task eq "EBD" || $killed_task eq "EBA" || $killed_task eq "ER"){
	    return (6); # era 4
	}
	else {
	    return (0); 
	}
    }


    if ($killer_task eq "EBA"  || $killer_task eq "EBD" || $killer_task eq "ESU" ){
	if ($killed_task eq "I" || $killed_task eq "ET"){
	    return (12); # era 8
	}
	else {
	    return (6); # era 0
	}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: Returning 0 points, cat determine Airkill points for $killer_name\n";
    $warnings++;
    return (0); 
}


# killer_code killed_code
sub get_gkill_points($$){
    my $killer_code = shift @_;
    my $killed_code = shift @_;
    my ($killer_name,$unused_army1)=get_name($killer_code);
    my ($killed_name,$unused_army2)=get_plane($killed_code);
    my $killer_task=get_task($killer_code);

    if ($killed_name =~ m/($TANK_REGEX)/){ # es tanque CHECK: guarda al agregar uevos tankes en generador
	if ($killer_task eq "BD") {return(8);}
	elsif ($killer_task eq "ET" || $killer_task eq "EBD") {return(4);}
	else {return(2);}
    }
    elsif ($killed_name =~ m/(88mm|20mm|25mm|85mm)/){ # es AAA
	if ($killer_task eq "BD" || $killer_task eq "BA" ||
	    $killer_task eq "ET" || $killer_task eq "EBA" || $killer_task eq "EBD" ) {return(2);}
	else {return(0);}
    }
    else { # otro ground
	if ($killer_task eq "BD" || $killer_task eq "BA") {return(1);}
	else {return(1);}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: Returning 0 points, cant determine Groundkill points for $killer_name\n";
    $warnings++;
    return (0); 
}

# army, task // asd check: puntos para los artilleros?? 
sub get_mis_result_points($$){
    my $army=shift @_;
    my $task=shift @_;
    my $sourvive=100; # default to 100

    if ($army==1) { # si es VVS
	if ($task eq "BA") {
	    if ($blue_damage >= 10) {return(10);}
	    if ($blue_damage >= 5) {return(5);}
	    return (0);
	}
	if ($task eq "BD") {
	    if ($BLUE_CAPTURA==1){return(0);}
	    else {return(10);}
	}
	if ($task eq "SUM") { 
	    if ($red_resuply >= 8) {return(20);}
	    if ($red_resuply >= 4) {return(10);}
	    return (0);
	}
	if ($task eq "EBA") {
	    $sourvive = get_task_perc_sorvive($army,"BA");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return (0);
	}
	if ($task eq "EBD") {
	    $sourvive = get_task_perc_sorvive($army,"BD");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return(0);
	}
	if ($task eq "ESU") {
	    $sourvive = get_task_perc_sorvive($army,"SUM");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return (0);
	}
	if ($task eq "I") {
	    if ($BLUE_SUM==1){
		$sourvive = get_task_perc_sorvive(2,"SUM");
		if ($sourvive == 0) {return(10);}
		if ($sourvive <= 50 ) {return(5);}
		return (0);
	    }
	    else {
		$sourvive = get_task_perc_sorvive(2,"BA");
		if ($sourvive == 0) {return(10);}
		if ($sourvive <= 50 ) {return(5);}
		return (0);
	    }
	}
	if ($task eq "ET") {
	    if ($RED_CAPTURA==1){return(10);}
	    else {return(0);}
	}
	if ($task eq "R") {return(0);}
	if ($task eq "ER") {return(0);}
    }

    if ($army==2) { # si es LW
	if ($task eq "BA") {
	    if ($red_damage >= 10) {return(10);}
	    if ($red_damage >= 5) {return(5);}
	    return (0);
	}
	if ($task eq "BD") {
	    if ($RED_CAPTURA==1){return(0);}
	    else {return(10);}
	}
	if ($task eq "SUM") { 
	    if ($blue_resuply >= 8) {return(20);}
	    if ($blue_resuply >= 4) {return(10);}
	    return (0);
	}
	if ($task eq "EBA") {
	    $sourvive = get_task_perc_sorvive($army,"BA");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return (0);
	}
	if ($task eq "EBD") {
	    $sourvive = get_task_perc_sorvive($army,"BD");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return (0);
	}
	if ($task eq "ESU") {
	    $sourvive = get_task_perc_sorvive($army,"SUM");
	    if ($sourvive == 100) {return(10);}
	    if ($sourvive >= 50 ) {return(5);}
	    return (0);
	}
	if ($task eq "I") {
	    if ($RED_SUM==1){
		$sourvive = get_task_perc_sorvive(1,"SUM");
		if ($sourvive == 0) {return(10);}
		if ($sourvive <= 50 ) {return(5);}
		return (0);
	    }
	    else {
		$sourvive = get_task_perc_sorvive(1,"BA");
		if ($sourvive == 0) {return(10);}
		if ($sourvive <= 50 ) {return(5);}
		return (0);
	    }
	}
	if ($task eq "ET") {
	    if ($BLUE_CAPTURA==1){return(10);}
	    else {return(0);}
	}
	if ($task eq "R") {return(0);}
	if ($task eq "ER") {return(0);}
    }

    print PAR_LOG " $MIS_TO_REP WARNING: Returning 0 points, cant determine mission points army:$army task:$task\n";
    $warnings++;
    return (0); 
}

sub detect_massive_disco(){
    my $last_disco_str_time="Not set";
    my $last_disco_time=0;
    my $same_time=0;

    seek LOG, 0, 0;
    while(<LOG>) {
	if ($_=~  m/([^ ]+) [^ ]+ has disconnected/){
	    if ($1 ne $stime_str) {
		if ($last_disco_str_time eq "Not set"){
		    $last_disco_str_time=$1;
		    $last_disco_time=get_segundos($1);
		    $first_case=1;
		}
		else {
		    my $diff= (get_segundos($1)- $last_disco_time);
		    if ( $diff<2  ) { # same disco time or +1 sec
			if ($first_case) {
			    $same_time+=2;
			    $first_case=0;
			}
			else {
			    $same_time++;
			}
			if ($diff) {
			    $last_disco_str_time=$1;
			    $last_disco_time=get_segundos($1);
			}
		    }
		    else {
			$last_disco_str_time=$1;
			$last_disco_time=get_segundos($1);
			$first_case=1;
		    }
		}
	    }
	}
    }
    if ($same_time){
	if ($same_time>2) {
	    $massive_disco=1;
	    print PAR_LOG " $MIS_TO_REP WARNING: $same_time pilots disconect simmilar time. massive_disco= $massive_disco\n";
	    $warnings++;
	}
    }
}


my @land_event_used=();
my @toff_event_used=();

sub search_for_rescuer($$$$$$){

    my ($cap_plane,$captured_time_str,$cx,$cy,$army,$wounded)=@_;
    my $line_back=tell LOG; # pos del log.

    my $ok_resc=0;
    my $resc_plane="";
    seek LOG,0,0;
    while (<LOG>) {
	if ($_=~ m/([^ ]+) ([^ ]+) landed at ([^ ]+) ([0-9.]+)/ && !$ok_resc) {
	    my $land_line=tell LOG; # pos del log.
	    my $land_time_str=$1;
	    $resc_plane=$2;
	    my $land_cx=$3;
	    my $land_cy=$4;

	    if ($cap_plane eq $resc_plane){next;}                  # itself land before capt
	    my ($by,$resc_army)=get_name($resc_plane);
	    my $html_by=$by;
	    $html_by =~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
	    $html_by =~ s/(.*)>(.*)/$1&gt;$2/g;
	    if ($resc_army!=$army){next;}                  # not same army
	    if (distance($cx,$cy,$land_cx,$land_cy)>5000){next;}      # not close landing
	    
	    my $land_ev_used=0;
	    my $search="$1 $2";
	    foreach my $land_ev (@land_event_used) {
		if ($land_ev eq $search){
		    $land_ev_used=1;
		    print WARN "--- $land_time_str $by landed used in other event\n";
		    print HTML_REP "--- $land_time_str $html_by landed used in other event\n";
		    last;
		}
	    }
	    if ($land_ev_used){next;}
 
	    print WARN "--- $land_time_str $by landed at [ $land_cx , $land_cy ] inside 5km limit\n";
	    print HTML_REP "--- $land_time_str $html_by landed at [ $land_cx , $land_cy ] inside 5km limit\n";


	    while (<LOG>) {
		if ($_=~ m/Mission END/){last;} # no scan after mission end line
		if ($_=~ m/([^ ]+) $resc_plane in flight at ([^ ]+) ([0-9.]+)/ && !$ok_resc ){

		    my $toff_time_str=$1;
		    my $toff_cx=$2;
		    my $toff_cy=$3;

		    my $toff_ev_used=0;
		    my $search="$1 $resc_plane";
		    foreach my $toff_ev (@toff_event_used) {
			if ($toff_ev eq $search){
			    $toff_ev_used=1;
			    print WARN "--- $toff_time_str $by take off used in other event\n";
			    print HTML_REP "--- $toff_time_str $html_by take off used in other event\n";
			    last;
			}
		    }
		    if ($toff_ev_used){next;}

		    print WARN "- $toff_time_str $by take off at [ $toff_cx , $toff_cy ] \n";
		    print HTML_REP "- $toff_time_str $html_by take off at [ $toff_cx , $toff_cy ] \n";

		    my $to_land_dist=int(distance($cx,$cy,$land_cx,$land_cy));
		    if ($to_land_dist <50) {$to_land_dist=50;} # assume always a minium of 50 meters to walk
		    my $to_toff_dist=int(distance($cx,$cy,$toff_cx,$toff_cy)) - 1500; # 1500 meters is roll distance
		    if ($to_toff_dist <50) {$to_toff_dist=50;} # assume always a minium of 50 meters to walk
		    print WARN "- distance to land place: $to_land_dist meters\n";
		    print HTML_REP "- distance to land place: $to_land_dist meters\n";
		    print WARN "- distance to toff place: $to_toff_dist meters\n";
		    print HTML_REP "- distance to toff place: $to_toff_dist meters\n";

		    my $distance=$to_toff_dist;
		    if ($to_land_dist<$to_toff_dist){
			$distance=$to_land_dist;
		    }
		    print WARN "- distance used to walk: $distance meters\n";
		    print HTML_REP "- distance used to walk : $distance meters\n";

		    if ($distance<5000) {

			my $captured_secs=get_segundos($captured_time_str);
			my $land_secs=get_segundos($land_time_str);
			my $toff_secs=get_segundos($toff_time_str);
			print WARN "- captured secs:$captured_secs\n- land_secs:$land_secs\n- toff_secs:$toff_secs\n";
			print HTML_REP "- captured secs:$captured_secs\n- land_secs:$land_secs\n- toff_secs:$toff_secs\n";

			my $start_walk_secs=$land_secs - 60;   # pilot start walking/running 1 min before landing
			if ($start_walk_secs<$captured_secs){  # but never before captured time
			    $start_walk_secs=$captured_secs;
			}
			if ($wounded==2){$start_walk_secs=$land_secs;} # pilot heavy wounded, cant walk, rescuer do
			my $stop_walk_secs=$toff_secs - 20;   # pilot stop waling/running 20 secs before toff
			my $walk_time=$stop_walk_secs-$start_walk_secs;
			print WARN "- start walk:$start_walk_secs\n- stop walk=$stop_walk_secs\n- walk time=$walk_time\n";
		       print HTML_REP "- start walk:$start_walk_secs\n- stop walk=$stop_walk_secs\n- walk time=$walk_time\n";

			my $walk_speed=5; # 5m/sec (18km/h = run) 
			if ($wounded==1){$walk_speed=2;} # 2m/sec (~ 7.2 km/h = walk)
			if ($wounded==2){$walk_speed=1;} # 1m/sec (~ 3.6 km/h = rescuer walk to him and back)
			my $walk_distance=$walk_time*$walk_speed;
			print WARN "- wounded=$wounded > walk speed=$walk_speed m/s > walk distance=$walk_distance meters\n";
			print HTML_REP "- wounded=$wounded > walk speed=$walk_speed m/s > walk distance=$walk_distance meters\n";

			if ($walk_distance>=$distance || $walk_time >=120){ # or 2 minutes (time simplification)
			    print WARN "- Distance inside range or 2 minutes walk time\n";
			    print HTML_REP "- Distance inside range or 2 minutes walk time\n";
			    print WARN "- Looking for $by return to base: ";
			    print HTML_REP "- Looking for $html_by return to base: ";
			    foreach my $en_base (@land_in_base) { 
				if ($en_base eq $resc_plane) { # si el recatador llego a la base
				    $ok_resc=1;
				    push (@land_event_used,"$land_time_str $resc_plane");
				    push (@toff_event_used,"$toff_time_str $resc_plane");
				    print WARN "Found!\n";
				    print HTML_REP "Found!\n";
				    my $temp;
				    while(1){
					$temp = shift (@land_in_base);
					if ($temp eq $resc_plane) {
					    last;
					}
					else {
					    push(@land_in_base,$temp);
					}
				    }
				    last;
				}
			    }
			    if (!$ok_resc) {
				print WARN "Not Found!\n";
				print HTML_REP "Not Found!\n";
			    }
			}
			else {
			    print WARN "- Not enought time to walk\n";
			    print HTML_REP "- Not enought time to walk\n";
			}
		    }
		    last; # last search for takeoff place
		}
	    }
	    seek LOG,$land_line,0; # regresamos 
	}
    }
    seek LOG,$line_back,0; # regresamos 
    return($ok_resc,$resc_plane);
}



sub print_pilot_actions(){


    my $hlname;
    my $regex_hlname;
    my $plane;
    my $wing;
    my $seat;
    my $by;
    my $to;
    my $planedam;
    my $planekill;
    my $friendplanekill;
    my $friendgrndkill;
    my $chutekill;
    my $kia_chute_dest;
    my $grndkill;
    my $use_landl;
    my $use_smoke;
    my @estado;
    my $stop_time;
    my $herido;
    my $landed;
    my $killed;
    my $bailed;
    my $bailed_cx;
    my $bailed_cy;
    my $para_landed;
    my $allow_disco;
    my $obj_army;
    my $pilot_army;
    my ($i,$j);
    my $fuel;
    my $weapons;
    my $captured;
    my $damaged;
    my $crash;
    my $in_flight;
    my $disco;
    my $plane_destroyed;
    my $rescued_by;
    my $line_back;
    my $play_task;
    my @rescatadores=();
    # my @rescatados=();  # definida como global para ser usarlo al determinar da~nos por kia/mia en AF

    my $pilot_fairp;   # experiencia piloto
    my $pilot_exp;   # experiencia piloto
    my $points;      # puntos piloto
    my $pnt_comments; # descripcion de puntos
    my $pnt_bgcolor;
    my $in_air;
    my $in_air_time_str;
    my $lights_status;
    my $time_of_landl;

    $red_points=0;
    $blue_points=0;

    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3>Pilots in mission:</h3></center>\n\n";
    print HTML_REP "<center>\n  <table width=\"800\"border=1>\n";


    for ( $j=1; $j<3; $j++){
	if ($j==1){
	    print HTML_REP "  <tr bgcolor=\"#eeaaaa\"><td colspan=14><strong>VVS</strong></td></tr>\n";
	    print HTML_REP "  <tr bgcolor=\"#ffffff\"><td class=\"ltr70\">Pilot</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Plane</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Task</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Points</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">F-time</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">A-K</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">G-k</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Fak</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Fgk</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Chu</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Smk</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Lig</td>\n";

	    print HTML_REP "    <td class=\"ltr70\">\n";
	    print HTML_REP "      <table border=\"0\">\n";
	    print HTML_REP "        <col width=\"28\"> <col width=\"21\"> <col width=\"21\"> ";
	    print HTML_REP "<col width=\"5\"> <col width=\"35\"> <col width=\"35\">\n"; 
	    print HTML_REP "        <tr>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Fire</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Ahit</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Ghit</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"center\">|</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\"><b>A%</b></td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\"><b>G%</b></td>\n";
	    print HTML_REP "        </tr>\n";
	    print HTML_REP "      </table></td>\n";

	    print HTML_REP "    <td class=\"ltr70\">State</td>\n";
	    print HTML_REP "  </tr>\n";
	}
	if ($j==2){
	    print HTML_REP "\n  <tr bgcolor=\"#ffffcc\"><td colspan=14></td></tr>\n\n"; # separador vvs/okl

	    print HTML_REP "  <tr bgcolor=\"#aaaaee\"><td colspan=14><strong>LW</strong></td></tr>\n";
	    print HTML_REP "  <tr bgcolor=\"#ffffff\"><td class=\"ltr70\">Pilot</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Plane</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Task</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Points</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">F-time</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">A-K</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">G-K</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Fak</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Fgk</td>\n";
	    print HTML_REP "    <td class=\"ltr70R\">Chu</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Smk</td>\n";
	    print HTML_REP "    <td class=\"ltr70\">Lig</td>\n";

	    print HTML_REP "    <td class=\"ltr70\">\n";
	    print HTML_REP "      <table border=\"0\">\n";
	    print HTML_REP "        <col width=\"28\"> <col width=\"21\"> <col width=\"21\"> ";
	    print HTML_REP "<col width=\"5\"> <col width=\"35\"> <col width=\"35\">\n"; 
	    print HTML_REP "        <tr>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Fire</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Ahit</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\">Ghit</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"center\">|</td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\"><b>A%</b></td>\n";
	    print HTML_REP "        <td class=\"ltr70\" align=\"right\"><b>G%</b></td>\n";
	    print HTML_REP "        </tr>\n";
	    print HTML_REP "      </table></td>\n";

	    print HTML_REP "    <td class=\"ltr70\">State</td>\n";
	    print HTML_REP "  </tr>\n";
	}
	for ( $i=0; $i<$hpilots; $i++){
	    if ($pilot_list[$i][5]==$j) {
		$hlname=$pilot_list[$i][0];

		$regex_hlname=$hlname;
		$regex_hlname =~ s/\\/\\\\/g; #algunos nombres son incompatibles con regex \
		$regex_hlname =~ s/\//\\\//g; #algunos nombres son incompatibles con regex /
		$regex_hlname =~ s/\|/\\\|/g; #algunos nombres son incompatibles con regex |
		$regex_hlname =~ s/\*/\\\*/g; #algunos nombres son incompatibles con regex *
		$regex_hlname =~ s/\(/\\\(/g; #algunos nombres son incompatibles con regex )
		$regex_hlname =~ s/\)/\\\)/g; #algunos nombres son incompatibles con regex (
		$regex_hlname =~ s/\+/\\\+/g; #algunos nombres son incompatibles con regex +
		$regex_hlname =~ s/\[/\\\[/g; #algunos nombres son incompatibles con regex [
		$regex_hlname =~ s/\]/\\\]/g; #algunos nombres son incompatibles con regex ]
		$regex_hlname =~ s/\'/\\\'/g; #algunos nombres son incompatibles con regex '
		$regex_hlname =~ s/\?/\\\?/g; #algunos nombres son incompatibles con regex ?

		my $html_hlname=$hlname;
		$html_hlname =~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
		$html_hlname =~ s/(.*)>(.*)/$1&gt;$2/g;
		my $url_hlname=$hlname;
		$url_hlname =~ s/(.*)\+(.*)/$1\%2B$2/g; #algunos nombres son incompatibles con url param 

		$plane=$pilot_list[$i][1];
		$seat=$pilot_list[$i][2];
		$seat =~ s/.*\(([0-9]+)\)/$1/;  # seat ahora contieene solo 0 o 1 ...
		$wing=$pilot_list[$i][4];
		$play_task=$pilot_list[$i][6];

		$by="";
		$to="";
		$planedam=0;
		$planekill=0;
		$friendplanekill=0;
		$friendgrndkill=0;
		$chutekill=0;
		$kia_chute_dest=0;
		$grndkill=0;
		$use_smoke=0;
		$stop_time=0;
		$end_hrs_vuelo=0;
		$herido=0;
		$landed=0;
		$killed=0;
		$bailed=0;
		$bailed_cx=0;
		$bailed_cy=0;
		$para_landed=0;
		$allow_disco=0;
		@estado=();
		$obj_army=0;
		$pilot_army=$j;
		$fuel="";
		$weapons="";
		$captured=0;
		$damaged=0;
		$crash=0;
		$in_flight=0;
		$disco=0;
		$plane_destroyed=0;

		$in_air=0;        # flag para indicar si esta volando o no
		$in_air_time_str="Not Set"; # hora despegue xx:xx:xx
		$lights_status=0; # flag para indicar estado landL Lights
		$use_landl=0;
		$time_of_landl="Not Used";

		$points=0;        # default valor en 0
		$pnt_comments=""; # default valor en ""
		$pilot_exp=0.9;     # default valor en 0.9
		$pilot_exp=get_pilot_exp($hlname); # buscar exp piloto
		$pilot_fairp=get_pilot_fairp($hlname); # buscar fairplay piloto
		$pnt_bgcolor="#ffffff";
		$pnt_comments.="Initial pilot Experience: $pilot_exp <br>";
		$pnt_comments.="Initial pilot Fairplay: $pilot_fairp <br>";

		
		my $not_in_base=1;
		foreach my $asalvo (@last_land_in_base) {
		    if ($asalvo eq $plane) {
			$not_in_base=0;
			last;
		    }
		}

		my $debug=0; # print bunch of garbage

		my $in;
		seek LOG, 0, 0;
		while(<LOG>) {
		    $in=$_;
		    if ($in=~  m/([^ ]+) ([^ ]+) seat occupied by $regex_hlname at ([^ ]+) ([^ ]+)/){
			if ($debug){print "$1 NSEAT $2\n";}
			$seat=$2;   # para detectar si cambio de asiento 
			$seat =~ s/.*\(([0-9]+)\)/$1/;  # seat ahora contieene solo (0) o (1) ...
		    }
		    if ($in=~  m/([^ ]+) $plane loaded weapons \'([^ ]+)\' fuel ([0-9%]+)/){
			$in_air=0;
			if ($debug){print "$1 LOAD $2 $3\n";}
			$weapons=$2;
			$fuel=$3;

			#if ($play_task eq "SUM" &&  ($fuel ne "100%" || $weapons ne "default")) { 
			if ($play_task eq "SUM" && $weapons ne "default") { 
			    # es SUM, pero no cargo 100 fuel ni default weapons -> lo pasamos a BA
			    $pilot_list[$i][6]="BA";
			    $play_task="BA";
			}
		    }

		    if ($weapons eq ""){next;} # para evitar leer eventos previos a tomar asiento (casos raros de restart)

		    if ($in=~  m/([^ ]+) $plane\($seat\) was wounded at ([^ ]+) ([^ ]+)/ && !$disco){
			if ($debug){print "$1 WOUN - $2 $3";}
			if ($herido==0){ 
			    push (@estado, "Wounded");
			    $herido=1;
			}
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) was heavily wounded at ([^ ]+) ([^ ]+)/ && !$disco){
			if ($debug){print "$1 HeWO - $2 $3";}
			if ($herido==0){ 
			    push (@estado, "Heavily wounded");
			    $herido=2;
			}
			elsif ($herido==1){ 
			    $herido=2;
			    my $temp_state= pop (@estado);
			    if ($temp_state eq "Wounded") {
				push (@estado, "Heavily wounded");
			    }
			    else {
				push (@estado, $temp_state);
				push (@estado, "Heavily wounded");
			    }
			}
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) bailed out at ([^ ]+) ([^ ]+)/ && !$disco){
			if ($debug){print "$1 BAIL - $2 $3";}
			if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
			if ($not_in_base==1) {
			    push (@estado, "Bailed");
			    $bailed=1;
			    $allow_disco=1;
			    $bailed_cx=$2;
			    $bailed_cy=$3; 
			}
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) successfully bailed out at ([^ ]+) ([^ ]+)/ && !$disco){
			if ($debug){print "$1 BaOK - $2 $3";}
			    $allow_disco=1;
			    $para_landed=1;
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) was captured at ([^ ]+) ([0-9.]+)/ && !$disco && !$killed){
			if ($debug){print "$1 CAPT - $2 $3";}
			push (@estado, "captured");
			$captured=1;
			$allow_disco=1;
			print WARN "$MIS_TO_REP <<*** $1 $hlname captured at [ $2 , $3 ]\n";
			print HTML_REP "\n <!--\n*** $1 $hlname captured at [ $2 , $3 ]\n";
			my ($ok_resc,$plane_resc)= search_for_rescuer($plane,$1,$2,$3,$pilot_army,$herido);
			
			if ($ok_resc){
			    if ($debug){print "RESCUED";}
			    $captured=0;
			    pop (@estado);
			    my ($by,$obj_army)=get_name($plane_resc);
			    print WARN "*** $hlname rescued by $by\n";
			    $by =~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
			    $by =~ s/(.*)>(.*)/$1&gt;$2/g;
			    print HTML_REP "*** $hlname rescued by $by\n-->\n\n";
			    push (@estado, "<br><b>Resc by: $by</b>");
			    push (@rescatadores,$by);
			    push (@rescatados,"$plane($seat)");
			    # db tabla  badc_rescues 
			    # misnum	       VARCHAR(30),
			    # misrep	       VARCHAR(30),
			    # rescatador       VARCHAR(30) BINARY ,
			    # rescatado	       VARCHAR(30) BINARY ,
			    $dbh->do("INSERT INTO $rescue_tbl VALUES (?,?,?,?)",undef,
				     $MIS_TO_REP,("rep".$ext_rep_nbr.".html"),$by,$hlname);
			}
			else{
			    print WARN "*** $hlname rescued failled\n";
			    print HTML_REP "*** $hlname rescued failled\n-->\n\n";
			}
			   
		    }

		    if ($in=~  m/([^ ]+) $plane\($seat\) was killed at ([^ ]+) ([^ ]+)/ && !$disco && !$captured){
			if ($debug){print "$1 KILL - $2 $3";}
			if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
			$stop_time=get_segundos($1);
			if (!$killed){  # si vale >0 ya le pusimos muerto
			    push (@estado, "Kia");
			    $killed=1;
			    $allow_disco=1;
			}
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) was killed by ([^ ]+) at ([^ ]+) ([^ ]+)/ && !$disco && !$captured){
			($by,$obj_army)=get_name($2);
			if ($debug){print "$1 KiBY $by $3 $4";}
			if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
			$stop_time=get_segundos($1);
			if (!$killed){  # si vale >0 ya le pusimos muerto
			    push (@estado, "Kia");
			    $killed=1;
			    $allow_disco=1;
			}
		    }
		    if ($in=~  m/([^ ]+) $plane\($seat\) was killed in his chute by ([^ ]+) at ([^ ]+) ([^ ]+)/ 
			&& !$disco && !$captured){
			($by,$obj_army)=get_name($2);
			if ($debug){print "$1 KiOC $by $3 $4";}
			if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
			$stop_time=get_segundos($1);
			if (!$killed){  # si vale >0 ya le pusimos muerto
			    push (@estado, "Killed in chute");
			    $killed=1;
			    $allow_disco=1;
			}
		    }
		    if ($in=~  m/([0-9:]+) $plane\($seat\) has chute destroyed by ([^ ]+) at ([^ ]+) ([^ ]+)/
			&& !$disco && !$captured){
			$by=get_name($2);
		        if ($debug){print "$1 KiCD $by $3 $4";}
			if (!$killed){  # si vale >0 ya le pusimos muerto
			    push (@estado, "Killed (para_dest)");
			    $kia_chute_dest=1;
			    $killed=1;
			    $allow_disco=1;
			    }
		    }
		    
		    # los sig eventos deven verificarse para el caso del que un gunner se haya desconectado
                                 
		    if ($in=~  m/([^ ]+) $plane turned landing lights on at ([^ ]+) ([^ ]+)/  && !$disco){
			$lights_status=1; 
			if ($debug){print "$1 Luces1 - $2 $3";}

			if ($in_air==1 && $use_landl==0) {
			    $time_of_landl=$1; # guardamos la hora de 1er luces on.
			    $use_landl=1;
			} 
		    }
		    
		    if ($in=~  m/([^ ]+) $plane turned landing lights off at ([^ ]+) ([^ ]+)/  && !$disco){
			$lights_status=0; 
			if ($debug){print "$1 Luces0 - $2 $3";}

			if ($in_air==1 && (get_segundos($1)<=(get_segundos($in_air_time_str)+300)) &&
			    (get_segundos($1)<=(get_segundos($time_of_landl)+300)) ){ #inair & <5min desp & 5min < 1st landl
			    $use_landl=0;     # borramos castigo uso luces
			    $time_of_landl=""; # borramos hora de uso luces
			}


		    }
		    if ($in=~  m/([^ ]+) $plane turned wingtip smokes on at ([^ ]+) ([^ ]+)/  && !$disco){
			if ($debug){print "$1 Humo1 - $2 $3";}
			if ((get_segundos($1) - get_segundos($stime_str))>60){ # 1 min  despues de mis start
			    if (!($play_task eq "SUM" || $play_task eq "R" || $play_task eq "ART" )){ # si no es: sum rec art
				$use_smoke=1;
			    }
			}
		    }
		    if ($in=~  m/([^ ]+) $plane turned wingtip smokes off at ([^ ]+) ([^ ]+)/  && !$disco){
			if ($debug){print "$1 Humo0 - $2 $3";}
		    }
		    if ($in=~  m/([^ ]+) $plane damaged by ([^ ]+) at ([^ ]+) ([^ ]+)/  && !$disco){
			($by,$obj_army)=get_name($2);
			if ($debug){print "$1 DaBY $by $3 $4";}
			#push (@estado, "Damaged");
			$damaged=1;
		    }
		    if ($in=~  m/([^ ]+) $plane shot down by ([^ ]+) at ([^ ]+) ([^ ]+)/  && !$disco){
			$in_air=0;
			my $vale=1;
			my $nocuenta;
			foreach $nocuenta (@last_land_in_base) {
			    if ($nocuenta eq $plane) {
				$vale=0;
				last;
			    }
			}
			foreach $nocuenta (@PKilled_pilots) {
			    if ($nocuenta eq $plane) {
				$vale=0;
				last;
			    }
			}
			if($vale){
			    ($by,$obj_army)=get_name($2);
			    if ($by eq "-") {($by,$obj_army)=get_plane($2);}
			    if ($debug){print "$1 SdBY $by $3 $4";}
			    if ($stop_time==0 || get_segundos($1)<($stop_time+5)) {
				if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
				if (!$bailed){$stop_time=get_segundos($1);}
				#if (!$landed) {push (@estado, "derribado");}
				$plane_destroyed=1;
			    }
			}
		    }
		    if ($in=~  m/([^ ]+) $plane in flight at ([^ ]+) ([^ ]+)/ && !$killed && !$disco && !$bailed){
			if ($debug){print "$1 Takeoff - $2 $3";}
			$in_air_time_str=$1;
			$in_air=1;
			$stop_time=0;
			$end_hrs_vuelo=0;

			if ($lights_status==1 && $use_landl==0) {
			    $use_landl=1;
			    $time_of_landl=$1; # guardamos la hora de 1er luces on.
			}
		    }

		    if ($in=~  m/([^ ]+) $plane landed at ([^ ]+) ([^ ]+)/ && !$killed && !$disco && !$bailed){
			if ($debug){print "$1 LAND - $2 $3";}
			$in_air=0;
			$stop_time=get_segundos($1);
			$end_hrs_vuelo=get_segundos($1); # esto deberia ir adiconando, pero al no haber evento takeoff
			$landed++; # queremos saber cuantas veces aterrizo
			push (@estado, "Landed");
			
			if ($use_landl==1) { # si uso luces que sea antes de  5 minutos de este aterrizaje
			    if ( ($stop_time-(get_segundos($time_of_landl)))<=300 ) {
				$use_landl=0; # lo perdonamos :)
				$time_of_landl=""; # borramos hora de uso luces
			    }
			}
		    }
		    if ($in=~ m/([^ ]+) $plane damaged on the ground at ([^ ]+) ([^ ]+)/ && !$killed && !$disco && !$bailed){
			$in_air=0;
			if ($debug){print "$1 DICH - $2 $3";}
			if ($stop_time==0 || get_segundos($1)<($stop_time+5)) {
			    $allow_disco=1;
			    if ($landed){
				my $temp_state =  pop (@estado);
				if ($temp_state eq "Landed"){
				    push (@estado, "Landed (emerg)");
				}
				else{
				    push (@estado, $temp_state);
				    push (@estado, "Landed (emerg)");
				}
			    }
			    else {
				push (@estado, "Damaged");
				$crash=1; # asd era damaged=1. pero no hay en los status% y sql el campo "damaged"
				$plane_destroyed=1;
				if ($in_air_time_str eq "Not Set") {
				    push (@estado,"take off accident");
				}
				else {
				    if($end_hrs_vuelo==0){
					$end_hrs_vuelo=get_segundos($etime_str);
				    }
				}
			    }
			}
			if ($use_landl==1) { # si uso luces que sea antes de  5 minutos de este aterrizaje
			    if ( ($stop_time-(get_segundos($time_of_landl)))<=300 ) {
				$use_landl=0; # lo perdonamos :)
				$time_of_landl=""; # borramos hora de uso luces
			    }
			}
		    }
		    if ($in=~  m/([^ ]+) $plane crashed at ([^ ]+) ([^ ]+)/ && !$killed && !$disco){
			$in_air=0;
			if ($debug){print "$1 CRSH - $2 $3";}
			if ($stop_time==0 || get_segundos($1)<($stop_time+5)) {
			    push (@estado, "Accident");
			    $crash=1;
			    $allow_disco=1;
			    $plane_destroyed=1;
			}
		    }
		    if ($in=~  m/([^ ]+) $regex_hlname has disconnected/){
			if ($1 ne $stime_str) {
			    if ($stop_time==0 || get_segundos($1)<($stop_time+1)) {
				$stop_time=get_segundos($1);
				if($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($1);}
				if (!($landed && !$not_in_base && $in_air==0) &&
				    !$allow_disco && !$massive_disco && $in_air_time_str ne "Not Set"){
				    if ($debug){print "$1 DISC\n";}
				    push (@estado, "Disconected");
				    $disco=1;
				    $pilot_fairp-=10; # 10% menos fairplay
				    $pnt_comments.="Disco :  Fairplay set to: $pilot_fairp <br>";
				}
			    }
			}
		    }
		    if ($in=~  m/([0-9:]+) ([^ ]+) destroyed by $plane at ([^ ]+) ([^ ]+)/  && !$disco ){
			($to,$obj_army)=get_plane($2);
			if ($obj_army==$pilot_army) { 
			    if ($debug){print "$1 FriKGR $to $3 $4";}
			    $friendgrndkill++;
			    $points-=5;
			    $pnt_comments.="-5 : Friendly gk $to <br>";
			}
			else {
			    if ($debug){print "$1 KiGR $to $3 $4";}
			    $grndkill++;
			    my $grnd_points=get_gkill_points($plane,$2);
			    $points+=$grnd_points;
			    if ($to =~ m/($TANK_REGEX)/){ # es tanque 
				$pilot_exp+=0.01;
				$pnt_comments.="+$grnd_points : gk $to : Exp +0.01 <br>";
			    }
			    else {
				$pilot_exp+=0.001;
				$pnt_comments.="+$grnd_points : gk $to : Exp +0.001 <br>";
			    }
			}
		    }
		    if ($in=~  m/([^ ]+) ([^ ]+)\(([0-9])\) was killed by $plane at ([^ ]+) ([^ ]+)/  && !$disco){
			($to,$obj_army)=get_name($2);
			if ($debug){print "$1 KiTO $to $4 $5";}

			if ( $3 == 0 && ($2 ne $plane)) { # si fue Pilot kill -> seat = 0 y no fue asi mismo
			    my $plane_pk=$2;
			    $plane_pk =~ s/(.*)\(0\)/$1/;
			    if ($obj_army==$pilot_army) { 
				$friendplanekill++;
				$points-=5;
				$pnt_comments.="-5 : Friendly ak $to <br>";
			    }
			    else {
				$planekill++;
				my $plane_points=get_akill_points($plane,$plane_pk);
				my $killed_exp=get_pilot_exp($to);
				$points+=int($plane_points * $killed_exp);
				$pilot_exp+=0.01;
				$pnt_comments.="+".int($plane_points * $killed_exp)." : pk $to &#32;&#32;($plane_points * $killed_exp) : Exp +0.01 <br>";
				
			    }
			}

		    }
		    if ($in=~  m/([^ ]+) ([^ ]+) damaged by $plane at ([^ ]+) ([^ ]+)/  && !$disco){
			($to,$obj_army)=get_name($2);
			if ($debug){print "$1 DaTO $to $3 $4";}
			$planedam++;
		    }
		    if ($in=~  m/([^ ]+) ([^ ]+) shot down by $plane at ([^ ]+) ([^ ]+)/  && !$disco){
			my $vale=1;
			my $nocuenta;
			foreach $nocuenta (@last_land_in_base) {
			    if ($nocuenta eq $2) {
				$vale=0;
				last;
			    }
			}
			foreach $nocuenta (@PKilled_pilots) {
			    if ($nocuenta eq $2) {
				$vale=0;
				last;
			    }
			}
			if($vale){
			    ($to,$obj_army)=get_name($2);
			    if ($debug){print "$1 SdTO $to $3 $4";}
			    if ($obj_army==$pilot_army) { 
				$friendplanekill++;
				$points-=5;
				$pnt_comments.="-5 : Friendly ak $to <br>";
			    }
			    else {
				$planekill++;
				my $plane_points=get_akill_points($plane,$2);
				my $killed_exp=get_pilot_exp($to);
				$points+=int($plane_points * $killed_exp);
				$pilot_exp+=0.01;
				$pnt_comments.="+".int($plane_points * $killed_exp)." : ak $to &#32;&#32;($plane_points * $killed_exp) : Exp +0.01 <br>";

			    }
			}
		    }
		    if ($in=~  m/([^ ]+) ([^ ]+) was killed in his chute by $plane at ([^ ]+) ([^ ]+)/ && !$disco){
			($to,$obj_army)=get_name($2);
			if ($debug){print "$1 CKTO $to $3 $4";}
			if ($2 !~ m/$plane/){ # si no es el propio o un crew
			    $chutekill++;
			    $points-=20;
			    $pilot_fairp-=25; # 25% menos fairplay
			    $pnt_comments.="-20 : chutekill $to  Fairplay set to: $pilot_fairp <br>";

			} 
		    }
		    if ($in=~  m/([^ ]+) ([^ ]+) has chute destroyed by $plane at ([^ ]+) ([^ ]+)/ && !$disco){
			($to,$obj_army)=get_name($2);
			if ($debug){print "$1 CDTO $to $3 $4";}
			if ($2 !~ m/$plane/){ # si no es el propio o un crew
			    $chutekill++;
			    $points-=20;
			    $pilot_fairp-=25; # 25% menos fairplay
			    $pnt_comments.="-20 : chutekill $to Fairplay set to: $pilot_fairp <br>";
			} 
		    }
		}
		#buscamos los detalles de  gunery
		my $fired=0;
		my $hit_total=0;
		my $hit_grnd=0;
		my $hit_air=0;
		seek LOG, 0, 0;
		while(<LOG>) {		
		    if ($_ =~ m/Name:.*$regex_hlname/ ){
			while(<LOG>) {
			    if ($_ =~ m/Fire\sBullets:\s+([0-9]+)/){
				if ($1>0){
				    $fired=$1;
				    $_ =readline(LOG);
				    $_ =~ m/Hit\sBullets:\s+([0-9]+)/;
				    $hit_total=$1;
				    $_ =readline(LOG);
				    $_ =~ m/Hit\sAir\sBullets:\s+([0-9]+)/;
				    $hit_air=$1;
				    $hit_grnd=$hit_total-$hit_air;
				    last;
				}
				last;
			    }
			}
		    }
		}
		if ( (scalar(@estado)==0) ){
		    if (!$plane_destroyed && $in_air) { 
			push (@estado,"In flight");
			$end_hrs_vuelo=get_segundos($etime_str);
			$in_flight=1;
		    }
		    elsif ($damaged)  { # casaos raros de damaged + disco
			push (@estado,"Damaged");
			if ($in_air_time_str eq "Not Set") {
			    push (@estado,"take off accident");
			}
			else {
			    if($end_hrs_vuelo==0){
				$end_hrs_vuelo=get_segundos($etime_str);
			    }
			}
			$crash=1;
		    }
		    else {
			if ($in_air_time_str eq "Not Set") {
			    push (@estado,"Did not take off");
			}
			else {
			    push (@estado,"Unknown");
			    if($end_hrs_vuelo==0){
				$end_hrs_vuelo=get_segundos($etime_str);
			    }
			}
		    }
		}
		
		if ($j==1) {
		    $pnt_bgcolor="#f2e0cf";
		    if (($i/2)-int($i/2)){
			print HTML_REP "  <tr bgcolor=\"#ffcccc\">\n";
		    }
		    else {
			print HTML_REP "  <tr bgcolor=\"#ffdddd\">\n";

		    }
		}
		if ($j==2) {
		    $pnt_bgcolor="#cfe0f2";
		    if (($i/2)-int($i/2)){
			print HTML_REP "  <tr bgcolor=\"#ccccff\">\n";
		    }
		    else {
			print HTML_REP "  <tr bgcolor=\"#dddddff\">\n";
		    }
		}
		
		# if safe in base we clear cptured (happens sometimes if land on base too close to front)
		if ($captured && !$not_in_base) {
		    $captured=0;
		    my $temp_state =  pop (@estado);
		    if ($temp_state ne "captured"){
			push (@estado, $temp_state);
		    }
		}

		if ($in_air && $not_in_base && !$in_flight && !$bailed && !$killed && !$captured && !$disco ){
		    push (@estado,"In flight");
		    $end_hrs_vuelo=get_segundos($etime_str);
		    $in_flight=1;
		}

		if ($in_air_time_str ne "Not Set" && $not_in_base && !$in_air && !$in_flight && 
		    !$bailed && !$killed && !$captured && !$disco ){ # if he taked off and ... 
		    if ($debug){print "CAPTURED : Unknow status\n";}
		    $captured=1;
		    push (@estado, "captured");
		    $pnt_comments.="Not safe in base and not bailed : MIA <br>";
		}

		if ($bailed && $not_in_base && !$para_landed &&!$killed && !$captured && !$disco ){
		    if (army_of_coordinates($bailed_cx,$bailed_cy) != $pilot_army){
			my $faraway = dist_to_friend_fm($bailed_cx,$bailed_cy,$pilot_army);
			$faraway-=7; # 7km is ~ max distance from frontline to FMarker (45 degree diagonal)
			my $chance_to_be_captured =  3*($faraway); # -21 to infinite. 
			my $luck=int(rand(100));
 			if ( $luck < $chance_to_be_captured){       
			    if ($debug){print "CAPTURED chances: $chance_to_be_captured luck: $luck \n";}
			    print WARN "$MIS_TO_REP $ext_rep_nbr $hlname CAPTURED cap: $chance_to_be_captured luck: $luck\n";
			    print HTML_REP "\n<!-- $html_hlname CAPTURED cap: $chance_to_be_captured luck: $luck -->\n";
			    push (@estado, "captured");
			    $captured=1;
			}
			else {
			    if ($debug){print "ESCAPED chances: $chance_to_be_captured luck: $luck \n";}
			    print WARN "$MIS_TO_REP $ext_rep_nbr $hlname ESCAPED cap: $chance_to_be_captured luck: $luck\n";
			    print HTML_REP "\n<!-- $html_hlname  ESCAPED  cap: $chance_to_be_captured luck: $luck  -->\n";
			}
		    }
		    else {
			if ($debug){print "ESCAPED Bailed on friend territory\n";}
			print WARN "$MIS_TO_REP $ext_rep_nbr $hlname ESCAPED Bailed on friend territory\n";
			print HTML_REP "\n<!-- $html_hlname  ESCAPED Bailed on friend territory -->\n";
		    }
		}
		if ($debug){print "avi: dam: $planedam - der: $planekill | Gkills: $grndkill\n";}
		if ($debug){print "estado: ".join(" ",@estado)."\n";}
		if ($debug){print "----------------------------------------------------\n";}

		# reduccion de estado de status para la BD
		if ($killed)  {$disco=0; $landed=0; $crash=0; $in_flight=0; $captured=0;$bailed=0;}
		if ($captured){$disco=0; $landed=0; $crash=0; $in_flight=0;             $bailed=0;}
		if ($disco)   {          $landed=0; $crash=0; $in_flight=0;             $bailed=0;}
		if ($bailed && $crash){$bailed=0;}
		if ($bailed && $landed){$landed=0;}
		if ($crash  && $landed){$landed=0;}
		if ($landed){$landed=1;} # reducimos a uno la cantidad de landings para DB

		if ($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($etime_str);}
		if ($end_hrs_vuelo==0){$end_hrs_vuelo=get_segundos($stime_str);}
		my $ftime=((int(($end_hrs_vuelo-get_segundos($stime_str))/36)/100));
		if ($in_air_time_str eq "Not Set") {$ftime=0;}
		
		if ($killed || ($captured && $not_in_base) || $disco ){ 
		    $points-=4;
		    $pnt_comments.="-4 : kia/mia/disco <br>";
		}
		elsif ($bailed || $crash) {
		    $points-=2;
		    $pilot_exp+=0.02; # alive
		    $pnt_comments.="-2 : bailed/crash :  Alive : Exp +0.02 <br>";
		}
		elsif ($landed && !$not_in_base && $ftime>0.1) { # ftime > 6 minutes
		    $points+=4;
		    $pnt_comments.="+4 : landed safe in base :  Alive + land : Exp +0.03 <br>";
		    $pilot_exp+=0.03; # alive + landed
		}
		else { # in_air u otro estado 
		    $pilot_exp+=0.02; # alive
		    $pnt_comments.="Alive: Exp +0.02 <br>";
		}

		($in,$obj_army)=get_plane($pilot_list[$i][1]);  # para obtener el nombre del avion en $in


		## pilot file

		$sth = $dbh->prepare("SELECT COUNT(*) FROM $pilot_file_tbl WHERE hlname=?");
		$sth->execute($hlname);
		@row = $sth->fetchrow_array;
		$sth->finish;
		if ($row[0]==0) { #pilot not exist on pilot_file : -> new pilot -> update values
		    my ($dia,$mes,$anio)=(localtime)[3,4,5];
		    $mes+=1;
		    $anio+=1900;
		    if ($mes <10){ $mes="0".$mes;}
		    if ($dia <10){ $dia="0".$dia;}
		    my $fecha = $anio."-".$mes."-".$dia;

		    $dbh->do("INSERT INTO $pilot_file_tbl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",undef,"",$hlname,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"NONE",1,0,0,$hlname,"email\@example.com","http://example.com/avatar.gif",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,$fecha,0.9,"",0,$INIT_BAN_PLANNIG);
		} 

		$sth = $dbh->prepare("SELECT pnt_steak,pnt_steak_max,mis_steak,mis_steak_max,a_steak,a_steak_max,g_steak,g_steak_max, akills, gkills, kia_mia, missions,disco, ban_hosting, ban_planing  FROM $pilot_file_tbl WHERE hlname=?");
		$sth->execute($hlname);
		@row = $sth->fetchrow_array;
		$sth->finish;
		
		my $pnt_steak=$row[0];
		my $pnt_steak_max=$row[1];
		my $mis_steak=$row[2];
		my $mis_steak_max=$row[3];
		my $a_steak=$row[4];
		my $a_steak_max=$row[5];
		my $g_steak=$row[6];
		my $g_steak_max=$row[7];

		my $tot_akill=$row[8]+$planekill;
		my $tot_gkill=$row[9]+$grndkill;
		my $tot_kia_mia=$row[10];
		my $tot_missions=$row[11]+1;
		my $tot_disco=$row[12];
		my $ban_hosting= $row[13];
		my $ban_planing= $row[14];
		
		if ($play_task eq "ART") { # si fue artillero, ponemos en 0 los gkills
		    $planekill=0;
		    $grndkill=0;
		}

		
		$mis_steak++;         if ($mis_steak>$mis_steak_max){$mis_steak_max=$mis_steak;}
		$a_steak+=$planekill; if ($a_steak>$a_steak_max){$a_steak_max=$a_steak;}
		$g_steak+=$grndkill;  if ($g_steak>$g_steak_max){$g_steak_max=$g_steak;}

		if ($killed || $captured){
		    $mis_steak=0;$a_steak=0;$g_steak=0;
		    $tot_kia_mia++;
		}

		my $akillswf=0;
		my $ahitwf=0;
		if ($hit_air && $planekill && $hit_grnd<20){ # para permitir impactos cuand avion explota etc..
		    $akillswf=$planekill;
		    $ahitwf=$hit_air;
		}
		my $ak_x_mis=$tot_akill/$tot_missions;
		my $gk_x_mis=$tot_gkill/$tot_missions;

		my $ak_x_kia=$tot_akill;
		my $gk_x_kia=$tot_gkill;
		if ($tot_kia_mia){
		    $ak_x_kia=$tot_akill/$tot_kia_mia;
		    $gk_x_kia=$tot_gkill/$tot_kia_mia;
		}

		if ($use_smoke){
		    $points-=5;
		    $pilot_fairp-=10; # 10% menos fairplay
		    $pnt_comments.="-5 : Use Wing tips Smoke  Fairplay set to: $pilot_fairp <br>";
		}

		if ($use_landl){
		    $points-=5;
		    $pilot_fairp-=10; # 10% menos fairplay
		    $pnt_comments.="-5 : Use Landing lights  Fairplay set to: $pilot_fairp <br>";
		}

		my $mis_points=get_mis_result_points($pilot_army,$play_task);
		$points+=$mis_points;
		$pnt_comments.="+$mis_points : Your mission task points <br>";

		my $host_bonus=4; # amount of bonus points because hosting
		if ($hlname eq $Download){
		    $points+=$host_bonus;
		    $pnt_comments.="+$host_bonus : Bonus points for hosts<br>";
		}

		$pnt_comments.="$points TOTAL MISSION POINS. <br>";


		if ($pilot_fairp == get_pilot_fairp($hlname)) {  # si el de la DB coincide, no hubo cambios
		    if ($pilot_fairp <100) {
			$pilot_fairp+=5; # 5% recover fairplay
			$pnt_comments.="Fairplay recovers +5% <br>";
		    }
		}
		# verificar que fairp sea mayor que 0 y menor que 100
		if ($pilot_fairp <0) {$pilot_fairp=0;}
		if ($pilot_fairp >100) {$pilot_fairp=100;}

		if ($pilot_exp >=3) {
		    $pilot_exp=3; 
		    $pnt_comments.="Pilot Exp reached max value of 3. Congratulations! <br>";
		}

		$points=int ($points * $pilot_exp * $pilot_fairp/100);
		$pnt_comments.="$points after EXP and FairP factors (* $pilot_exp * $pilot_fairp /100) <br>";
		if ($points <0 ) {
		    $points=0;
		    $pnt_comments.="Negative points ->  0 points <br>";
		}
		$pnt_steak+=$points;  if ($pnt_steak>$pnt_steak_max){$pnt_steak_max=$pnt_steak;}
		if ($killed || $captured){
		    $pnt_steak=0;
		}

		if ($j==1){ # red pilot
		    $red_points+=$points;
		}
		else{ # blue pilot
		    $blue_points+=$points;
		}

		if ($disco && !$killed && !$captured){ # resetamos pilot_exp
		    $pilot_exp= int($pilot_exp * 1000 * 0.75)/1000;
		    if ($pilot_exp <(0.9+($tot_missions/1000))) { 
			$pilot_exp=0.9+($tot_missions/1000);
		    }
		    $pnt_comments.="Pilot experience reset to $pilot_exp <br>";
		}
		if ($killed || $captured){ # resetamos pilot_exp
		    $pilot_exp=0.9+($tot_missions/1000);
		    $pnt_comments.="Pilot experience reset to $pilot_exp <br>";
		}
		if ($ban_planing==1 &&  $tot_missions == $MIN_MIS_TO_PLAN) {
		    $ban_planing=0;
		}

		# pilot file update
		$dbh->do("UPDATE $pilot_file_tbl SET missions = missions + 1, ftime = ftime + $ftime, akills = akills + $planekill, akillswf = akillswf + $akillswf, gkills = gkills + $grndkill, smoke = smoke + $use_smoke, lights = lights + $use_landl, mis_steak = $mis_steak, mis_steak_max = $mis_steak_max, a_steak = $a_steak, a_steak_max = $a_steak_max, g_steak = $g_steak, g_steak_max = $g_steak_max, disco = disco + $disco, killed = killed + $killed, bailed = bailed + $bailed,  captured = captured + $captured, landed = landed + $landed, crash = crash + $crash, in_flight = in_flight + $in_flight, fired = fired + $fired, ahit = ahit + $hit_air, ahitwf = ahitwf + $ahitwf, ghit = ghit + $hit_grnd, chutes = chutes + $chutekill, friend_gk = friend_gk + $friendgrndkill, friend_ak = friend_ak + $friendplanekill, kia_mia = $tot_kia_mia, ak_x_mis = $ak_x_mis, gk_x_mis = $gk_x_mis, ak_x_kia = $ak_x_kia, gk_x_kia = $gk_x_kia,  experience = $pilot_exp, points = points + $points, pnt_steak = $pnt_steak, pnt_steak_max = $pnt_steak_max, fairplay = $pilot_fairp, ban_hosting = $ban_hosting, ban_planing = $ban_planing WHERE hlname=\"$hlname\"");

		if ($play_task eq "I"){$play_task="INT";}
		# pilot mis entry
		if ($fired){
		$dbh->do("INSERT INTO $pilot_mis_tbl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
			   undef,
			   $hlname,$in,$pilot_list[$i][3],((int(($end_hrs_vuelo-get_segundos($stime_str))/36)/100)),
			   $planekill,$grndkill,$friendplanekill,$friendgrndkill,$chutekill,$use_smoke,$use_landl,
			   $fired,$hit_air,$hit_grnd,(int($hit_air/$fired*1000)/10),(int($hit_grnd/$fired*1000)/10),
			   join(" ",@estado),$MIS_TO_REP,("rep".$ext_rep_nbr.".html"),$disco,$killed,$bailed,$captured,
			   $landed,$crash,$in_flight,$fuel,$weapons,$play_task,$points,$MAP_NAME_LONG);
	      }
		else {
		$dbh->do("INSERT INTO $pilot_mis_tbl VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
			   undef,
			   $hlname,$in,$pilot_list[$i][3],((int(($end_hrs_vuelo-get_segundos($stime_str))/36)/100)),
			   $planekill,$grndkill,$friendplanekill,$friendgrndkill,$chutekill,$use_smoke,
			   $use_landl,"0","0","0","0","0",join(" ",@estado),$MIS_TO_REP,("rep".$ext_rep_nbr.".html"),
			   $disco,$killed,$bailed,$captured,$landed,$crash,$in_flight,$fuel,$weapons,$play_task,
			   $points,$MAP_NAME_LONG);
		}
		if ($play_task eq "INT"){$play_task="I";}

		# Actualizar Sqd stats, si piloto pertence a sqd
		$sth = $dbh->prepare("SELECT sqd_accepted, in_sqd_id  FROM $pilot_file_tbl WHERE hlname=?");
		$sth->execute($hlname);
		@row = $sth->fetchrow_array;
		$sth->finish;
		if ($row[0]==1) {  # sqd_accepted = 1
		    my $sqd_id=$row[1];
		    my $muerto = $killed + $captured;
		    if ($muerto) { $muerto =1;} # evitar posible? caso de piloto kia=1 y  captured=1 => muerto=2;

		    $dbh->do("UPDATE $sqd_file_tbl SET totalmis = totalmis + 1, totalakill = totalakill + $planekill, totalgkill = totalgkill + $grndkill, totalpoints = totalpoints + $points, totalkiamia = totalkiamia + $muerto  WHERE id=\"$sqd_id\"");
		    $sth = $dbh->prepare("SELECT totalmis,totalakill,totalgkill,totalpoints,totalkiamia FROM $sqd_file_tbl WHERE id=?");
		    $sth->execute($sqd_id);
		    @row = $sth->fetchrow_array;
		    $sth->finish;
		    if ($row[0] >0) {  # misones >0 
			my $ak_x_mis= $row[1]/$row[0];
			my $gk_x_mis=$row[2]/$row[0];
			my $points_x_mis=$row[3]/$row[0];
			my $kia_x_mis=$row[4]/$row[0];
			$dbh->do("UPDATE $sqd_file_tbl SET ak_x_mis = $ak_x_mis, gk_x_mis = $gk_x_mis, points_x_mis = $points_x_mis, kia_x_mis = $kia_x_mis  WHERE id=\"$sqd_id\"");
		    }
		}

		print HTML_REP "  <td class=\"ltr70\"><b><a href=\"/pilot.php?hlname="
		    .$url_hlname."\">".$html_hlname."</a></b></td>\n";
		print HTML_REP "  <td class=\"ltr70\">".$in."</td>\n";
		if ($play_task eq "I"){$play_task="INT";}
		print HTML_REP "  <td class=\"ltr70\"><center><a href=\"/tasks.html\" title=\"".$pilot_list[$i][3]." - Code: $plane  - Weapons: $weapons - Fuel: $fuel \">".$play_task."</a></center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center><a href=\"/points.html\" onMouseover=\"ddrivetip(\'$pnt_comments\',\'$pnt_bgcolor\',\'550\')\" onMouseout=\"hideddrivetip()\">".$points."</a></center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$ftime."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$planekill."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$grndkill."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$friendplanekill."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$friendgrndkill."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$chutekill."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$use_smoke."</center></td>\n";
		print HTML_REP "  <td class=\"ltr70\"><center>".$use_landl."</center></td>\n";

		print HTML_REP "  <td class=\"ltr70\">";
		if ($fired){
		    print HTML_REP "\n";
		    print HTML_REP "    <table border=\"0\">\n";		    
		    print HTML_REP "      <col width=\"28\"> <col width=\"21\"> <col width=\"21\"> ";
		    print HTML_REP "<col width=\"5\"> <col width=\"35\"> <col width=\"35\">\n"; 
		    print HTML_REP "      <tr>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"right\">".$fired."</td>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"right\">".$hit_air."</td>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"right\">".$hit_grnd."</td>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"center\">|</td>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"right\">".(int($hit_air/$fired*1000)/10)."%</td>\n";
		    print HTML_REP "      <td class=\"ltr70\" align=\"right\">".(int($hit_grnd/$fired*1000)/10)."%</td>\n";
		    print HTML_REP "      </tr>\n";
		    print HTML_REP "    </table></td>\n";
		}
		else {
		    print HTML_REP "<center>-</center></td>\n";
		}

		print HTML_REP "  <td class=\"ltr70\">".join(" ",@estado)."</td>\n";
		print HTML_REP "</tr>\n";
	    }
	}
    }
    print HTML_REP "</table>\n</center>\n\n\n";

    foreach my $piloto (@rescatadores) {
	$dbh->do("UPDATE $pilot_file_tbl SET rescues = rescues + 1, fairplay = 100, experience = experience + 0.1  WHERE hlname=\"$piloto\"");
    }

    # actualizamos medallas
    for (my $i=0 ; $i<$hpilots; $i++){
	my $piloto = $pilot_list[$i][0];
	$sth = $dbh->prepare("SELECT fairplay, points, akills, gkills, rescues, pnt_steak FROM $pilot_file_tbl WHERE hlname=?");
	$sth->execute($piloto);
	@row = $sth->fetchrow_array;
	$sth->finish;
	my $fairplay=$row[0];
	my $points=$row[1];
	my $akills=$row[2];
	my $gkills=$row[3];
	my $rescues=$row[4];
	my $pnt_steak=$row[5];
	if ($fairplay == 100) {
	    my $res_med=0;
	    my $air_med=0;
	    my $gnd_med=0;
	    my $rank=0;
	    my $alive_medal=0;

	    if ($rescues > 0 ) {$res_med=1;}
	    if ($rescues > 4 ) {$res_med=2;}
	    if ($rescues > 9 ) {$res_med=3;}
	    if ($rescues > 14) {$res_med=4;}

	    if ($akills >19 ) {$air_med=1;}
	    if ($akills >49 ) {$air_med=2;}
	    if ($akills >99 ) {$air_med=3;}
	    if ($akills >199) {$air_med=4;}
	    if ($akills >299) {$air_med=5;}

	    if ($gkills >99  ) {$gnd_med=1;}
	    if ($gkills >249 ) {$gnd_med=2;}
	    if ($gkills >499 ) {$gnd_med=3;}
	    if ($gkills >999 ) {$gnd_med=4;}
	    if ($gkills >1499) {$gnd_med=5;}

	    if ($points >     0) {$rank=1;}
	    if ($points >=  100) {$rank=2;}  # ~  10 sorties
	    if ($points >=  250) {$rank=3;}  # ~  25 sorties
	    if ($points >=  500) {$rank=4;}  # ~  50 sorties
	    if ($points >= 1000) {$rank=5;}  # ~ 100 sorties
	    if ($points >= 2000) {$rank=6;}  # ~ 200 sorties
	    if ($points >= 4000) {$rank=7;}  # ~ 300 sorties

	    if ($pnt_steak >     0) {$alive_medal=1;}
	    if ($pnt_steak >=   50) {$alive_medal=2;}  # ~   5 sorties
	    if ($pnt_steak >=  100) {$alive_medal=3;}  # ~  10 sorties
	    if ($pnt_steak >=  250) {$alive_medal=4;}  # ~  25 sorties
	    if ($pnt_steak >=  500) {$alive_medal=5;}  # ~  50 sorties
	    if ($pnt_steak >=  750) {$alive_medal=6;}  # ~  75 sorties
	    if ($pnt_steak >= 1000) {$alive_medal=7;}  # ~ 100 sorties

	    
	    my $medals = 1000 * $res_med + 100 * $air_med + 10 * $gnd_med + $alive_medal;
	    $dbh->do("UPDATE $pilot_file_tbl SET rank = $rank, medals = $medals  WHERE hlname=\"$piloto\"");	    
	}
    }
}


sub eventos_aire(){
    my $i=0;
    my $to_army;
    my $by_army;
    my $letra="ltr70";
    my $by;
    my $to;
    my $wasfriend=0;

    my @kia_mia_list=();


    #print "\nDerribos:\n"; # debug, sacar
    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3>Air Events:</h3></center>\n\n";
    print HTML_REP "<center>\n<table border=1>\n";
    print HTML_REP "  <tr bgcolor=\"#ffffff\">\n";
    print HTML_REP "    <td class=\"ltr70\">Time</td>\n";
    print HTML_REP "    <td class=\"ltr70\">pilot</td>\n";
    print HTML_REP "    <td class=\"ltr70\">plane/obj.</td>\n";
    print HTML_REP "    <td class=\"ltr70\">downs</td>\n";
    print HTML_REP "    <td class=\"ltr70\">plane</td>\n";
    print HTML_REP "  </tr>\n";

    my $down_x;
    my $down_y;
    my $icon="";
    if ($unix_cgi){
	if ($WINDOWS) {
	    eval `copy $PATH_TO_WEBROOT\\images\\front.jpg $PATH_TO_WEBROOT\\images\\front$ext_rep_nbr.jpg`; # win
	}
	else {
	    eval `cp $PATH_TO_WEBROOT/images/front.jpg $PATH_TO_WEBROOT/images/front$ext_rep_nbr.jpg`;
	}
    }
    open (MAP_REP1,">$PATH_TO_WEBROOT/rep/map_1x$ext_rep_nbr.html");
    open (MAP_REP2,">$PATH_TO_WEBROOT/rep/map_2x$ext_rep_nbr.html");
    open (MAP_REP4,">$PATH_TO_WEBROOT/rep/map_4x$ext_rep_nbr.html");

    print MAP_REP1 <<REP1;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<TITLE>MAPA</TITLE>
<BODY bgColor="#ffffcc">
<DIV style="LEFT: 0px; TOP: 0px; POSITION: absolute;">
  <IMG alt="" src="../images/front$ext_rep_nbr.jpg" width="900" height="780"  border=0> 
</DIV>
REP1
    ;
    print MAP_REP2 <<REP2;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<TITLE>MAPA</TITLE>
<BODY bgColor="#ffffcc">
<DIV style="LEFT: 0px; TOP: 0px; POSITION: absolute;">
  <IMG alt="" src="../images/front$ext_rep_nbr.jpg" width="1800" height="1560"  border=0> 
</DIV>
REP2
    ;
    print MAP_REP4 <<REP4;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<TITLE>MAPA</TITLE>
<BODY bgColor="#ffffcc">
<DIV style="LEFT: 0px; TOP: 0px; POSITION: absolute;">
  <IMG alt="" src="../images/front$ext_rep_nbr.jpg" width="3600" height="3120"  border=0> 
</DIV>
REP4
    ;
    my $print_event=0;
    my $time_evento;
    my $base_AF="";
    my $in;
    my $task_killer="";
    my $task_killed="";

    seek LOG, 0, 0;
    while(<LOG>) {
	$in=$_;
	$task_killer="";
	$task_killed="";
	if ($in =~  m/([^ ]+) ([^ ]+) shot down by ([^ ]+) at ([^ ]+) ([^ ]+)/){
	    $base_AF=get_base_AF($2);
	    my $vale=1;
	    my $nocuenta;
	    foreach $nocuenta (@last_land_in_base) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    foreach $nocuenta (@PKilled_pilots) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    if($vale){
		$time_evento=$1;
		($to,$to_army)=get_name($2);
		($plane_to,$to_army)=get_plane($2);
		$task_killed=get_task($2);
		if ($task_killed eq "I") {$task_killed="INT";}
		if ($task_killed ne "") {$task_killed= "<font size=\"-6\">&nbsp;&nbsp;($task_killed)</font>";}

		if ($to_army ==1) { $red_planes_destroyed++;}
		if ($to_army ==2) { $blue_planes_destroyed++;}

		($by,$by_army)=get_name($3);
		($plane_by,$by_army)=get_plane($3);
		$task_killer=get_task($3);
		if ($task_killer eq "I") {$task_killer="INT";}
		if ($task_killer ne "") {$task_killer= "<font size=\"-6\">&nbsp;&nbsp;($task_killer)</font>";}

		$print_event=1;
		$down_x=$4;
		$down_y=$5;
	    }
	}
	elsif ($in =~  m/([^ ]+) ([^ ]+) crashed at ([^ ]+) ([^ ]+)/){
	    $base_AF=get_base_AF($2);
	    my $vale=1;
	    my $nocuenta;
	    foreach $nocuenta (@last_land_in_base) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    foreach $nocuenta (@PKilled_pilots) {
		if ($nocuenta eq $2) {
		    $vale=0;
		    last;
		}
	    }
	    if($vale){
		$time_evento=$1;
		($to,$to_army)=get_name($2);
		($plane_to,$to_army)=get_plane($2);
		$task_killed=get_task($2);
		if ($task_killed eq "I") {$task_killed="INT";}
		if ($task_killed ne "") {$task_killed= "<font size=\"-6\">&nbsp;&nbsp;($task_killed)</font>";}
		
		if ($to_army ==1) { $red_planes_destroyed++;}
		if ($to_army ==2) { $blue_planes_destroyed++;}
		$by="-";
		$plane_by="Accident";
		$by_army=8; # no army 
		$print_event=1;
		$down_x=$3;
		$down_y=$4;
	    }
	}
	elsif  ($in =~ m/([^ ]+) ([^ ]+)\(0\) was killed by ([^ ]+) at ([^ ]+) ([^ ]+)/ && ($2 ne $3)){
	    $base_AF=get_base_AF($2);
	    $time_evento=$1;
	    ($to,$to_army)=get_name($2);
	    ($plane_to,$to_army)=get_plane($2);
	    $task_killed=get_task($2);
	    if ($task_killed eq "I") {$task_killed="INT";}
	    if ($task_killed ne "") {$task_killed= "<font size=\"-6\">&nbsp;&nbsp;($task_killed)</font>";}
	    
	    if ($to_army ==1) { $red_planes_destroyed++;}
	    if ($to_army ==2) { $blue_planes_destroyed++}
	    
	    ($by,$by_army)=get_name($3);
	    ($plane_by,$by_army)=get_plane($3);
	    $task_killer=get_task($3);
	    if ($task_killer eq "I") {$task_killer="INT";}
	    if ($task_killer ne "") {$task_killer= "<font size=\"-6\">&nbsp;&nbsp;($task_killer)</font>";}
	    
	    $print_event=1;
	    $down_x=$4;
	    $down_y=$5;
	}
	if ($print_event){
	    $print_event=0;
	    #print "$1 $by  $plane_by derriba a $to  $plane_to\n"; # debug sacar
	    my $html_by=$by;
	    my $html_to=$to;
	    $html_by =~ s/(.*)<(.*)/$1&lt;$2/; #algunos nombres son incompatibles con html <
	    $html_by =~ s/(.*)>(.*)/$1&gt;$2/;
	    $html_to =~ s/(.*)<(.*)/$1&lt;$2/; #algunos nombres son incompatibles con html <
	    $html_to =~ s/(.*)>(.*)/$1&gt;$2/;
	    $i++;
	    if (($i/2)-int($i/2)){print HTML_REP "  <tr bgcolor=\"#ccffcc\">\n";}
	    else {print HTML_REP "  <tr bgcolor=\"#cceedd\">\n";}
	    
	    if ( ($plane_by eq $plane_to) || ($by_army==$to_army)) { $letra="ltr70R"; $wasfriend=1;} 
	    else { $letra="ltr70"; $wasfriend=0;}
	    print HTML_REP "    <td class=\"$letra\">$time_evento</td>\n";
	    print HTML_REP "    <td class=\"$letra\">$html_by</td>\n";
	    print HTML_REP "    <td class=\"$letra\" align=\"right\">$plane_by $task_killer</td>\n";
	    print HTML_REP "    <td class=\"$letra\">$html_to</td>\n";
	    print HTML_REP "    <td class=\"$letra\" align=\"right\">$plane_to $task_killed</td>\n";
	    print HTML_REP "  </tr>\n";

	    # db table badc_air_event
	    #       misnum	       VARCHAR(30),
	    #       misrep	       VARCHAR(30),
	    #       hlkiller	       VARCHAR(30) BINARY ,
	    #       plane_killer       VARCHAR(60),
	    #       hlkilled	       VARCHAR(30) BINARY ,
	    #       plane_killed       VARCHAR(60),
	    #	    wasfriend          CHAR(3),
	    $dbh->do("INSERT INTO $air_events_tbl VALUES (?,?,?,?,?,?,?)",undef,$MIS_TO_REP,("rep".$ext_rep_nbr.".html"),$by,$plane_by,$to,$plane_to,$wasfriend);


	    if ($base_AF eq $red_af1_code) { $red_af1_lost++;}
	    if ($base_AF eq $red_af2_code) { $red_af2_lost++;}
	    if ($base_AF eq $blue_af1_code) { $blue_af1_lost++;}
	    if ($base_AF eq $blue_af2_code) { $blue_af2_lost++;}

	    if ($to_army==1) {$icon="../images/blue_dot.gif";}
	    if ($to_army==2) {$icon="../images/red_dot.gif";}
	    my $icon_left_pos= int(($down_x/$MAP_RIGHT)* $ANCHO)-2;
	    my $icon_top_pos= int($ALTO-(($down_y/$MAP_TOP)* $ALTO))-2;

	    print MAP_REP1 "<DIV style=\"LEFT: ".$icon_left_pos."px; TOP: ".$icon_top_pos."px; POSITION: absolute;\">\n";
	    print MAP_REP1 "<IMG title=\"[$time_evento] $html_by ($plane_by) downs $html_to ($plane_to)\" src=\"$icon\"></DIV>\n";

            $icon_left_pos *=2;
	    $icon_top_pos *=2;

	    print MAP_REP2 "<DIV style=\"LEFT: ".$icon_left_pos."px; TOP: ".$icon_top_pos."px; POSITION: absolute;\">\n";
	    print MAP_REP2 "<IMG title=\"[$time_evento] $html_by ($plane_by) downs $html_to ($plane_to)\" src=\"$icon\"></DIV>\n";

            $icon_left_pos *=2;
	    $icon_top_pos *=2;

	    print MAP_REP4 "<DIV style=\"LEFT: ".$icon_left_pos."px; TOP: ".$icon_top_pos."px; POSITION: absolute;\">\n";
	    print MAP_REP4 "<IMG title=\"[$time_evento] $html_by ($plane_by) downs $html_to ($plane_to)\" src=\"$icon\"></DIV>\n";

	} # end if print_event (shotdown o crashed)

	# determinacion de kia / mia  para perdidas en AF
	if ($in=~  m/[^ ]+ ([^ ]+) was captured at / || 
	    $in=~  m/[^ ]+ ([^ ]+) was killed at / ||
	    $in=~  m/[^ ]+ ([^ ]+) was killed by / ||
	    $in=~  m/[^ ]+ ([^ ]+) was killed in his chute by / ||
	    $in=~  m/[^ ]+ ([^ ]+) has chute destroyed by / ){
	    my $plane=$1;
	    my $seat=$1;
	    $plane =~ s/(.*)\([0-9]+\)/$1/;
	    $seat =~ s/.*\(([0-9]+)\)/$1/;
	    if ($seat == 0) { # solo miramos los pilotos
		my $continue=1;
		my $en_lista="";
		foreach $en_lista (@kia_mia_list) { # si nolo contamos antes (no especificamos piloto aqui)
		    if ($en_lista eq $plane) {
			$continue=0;
			last;
		    }
		}
		if ($continue) {
		    foreach $en_lista (@rescatados) { # y si no fueron rescatados
			if ($en_lista eq "$plane(0)" ) {
			    $continue=0;
			    last;
			}
		    }
		}
		if ($continue) { 
		    $base_AF=get_base_AF($plane);
		    if ($base_AF eq $red_af1_code) { $red_af1_kia++;}
		    if ($base_AF eq $red_af2_code) { $red_af2_kia++;}
		    if ($base_AF eq $blue_af1_code) { $blue_af1_kia++;}
		    if ($base_AF eq $blue_af2_code) { $blue_af2_kia++;}
		    push (@kia_mia_list, $plane); # poner el piloto en kia_mia_list, solo avion, sin piloto (0).
		}
	    }
	} # end calculo de kia/mia para perdidas AF
    } # end while <log>

    print HTML_REP "<tr bgcolor=\"#ffffff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Total VVS losts (Planes/Pilots)</td><td align=\"center\" class=\"ltr80\"><b> $red_planes_destroyed / ".($red_af1_kia+$red_af2_kia)." </b></td></tr>\n";
    print HTML_REP "<tr bgcolor=\"#ffffff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Total LW losts (Planes/Pilots)</td><td align=\"center\" class=\"ltr80\"><b> $blue_planes_destroyed / ".($blue_af1_kia+$blue_af2_kia)."</b></td></tr>\n";

    my $red_af1_name="";
    my $red_af2_name="";
    my $blue_af1_name="";
    my $blue_af2_name="";

    my $red_af1_captured=0;
    my $red_af2_captured=0;
    my $blue_af1_captured=0;
    my $blue_af2_captured=0;

    open (TEMPGEO, ">temp_geo.data"); #
    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) {
	if ($_ !~ m/^($red_af1_code,|$red_af2_code,|$blue_af1_code,|$blue_af2_code,)/) { # si no es una line que interesa...
	    print TEMPGEO;
	}
	else { 
	    if ($_ =~ m/^$red_af1_code,([^,]+),.*,([^:]+):[12]/){ 
		$red_af1_name=$1;
		$dam=int(($2+$red_af1_lost*$AF_PLANE_LOST_DAM+$red_af1_kia*$AF_PILOT_LOST_DAM)*100)/100; 
		if ($dam>100) {$dam=100;}
		if ($_ =~ s/^($red_af1_code,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:1/$1,$dam:1/){ 
		    print TEMPGEO;
		}
		else { # if regex fail is because army is not 1, so AF is now blue, print without damage
		    $red_af1_captured=1; 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$red_af2_code,([^,]+),.*,([^:]+):[12]/){ 
		$red_af2_name=$1;
		$dam=int(($2+$red_af2_lost*$AF_PLANE_LOST_DAM+$red_af2_kia*$AF_PILOT_LOST_DAM)*100)/100; 
		if ($dam>100) {$dam=100;}
		if ($_ =~ s/^($red_af2_code,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:1/$1,$dam:1/){ 
		    print TEMPGEO;
		}
		else { # if regex fail is because army is not 1, so AF is now blue, print without damage
		    $red_af2_captured=1; 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$blue_af1_code,([^,]+),.*,([^:]+):[12]/){ 
		$blue_af1_name=$1;
		$dam=int(($2+$blue_af1_lost*$AF_PLANE_LOST_DAM+$blue_af1_kia*$AF_PILOT_LOST_DAM)*100)/100;
		if ($dam>100) {$dam=100;}
		if ($_ =~ s/^($blue_af1_code,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:2/$1,$dam:2/){ 
		    print TEMPGEO;
		}
		else { # if regex fail is because army is not 2, so AF is now red, print without damage
		    $blue_af1_captured=1; 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$blue_af2_code,([^,]+),.*,([^:]+):[12]/){ 
		$blue_af2_name=$1;
		$dam=int(($2+$blue_af2_lost*$AF_PLANE_LOST_DAM+$blue_af2_kia*$AF_PILOT_LOST_DAM)*100)/100;
		if ($dam>100) {$dam=100;}
		if ($_ =~ s/^($blue_af2_code,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:2/$1,$dam:2/){ 
		    print TEMPGEO;
		}
		else { # if regex fail is because army is not 2, so AF is now red, print without damage
		    $blue_af2_captured=1; 
		    print TEMPGEO;
		}
	    }
	}
    }
    close(TEMPGEO);
    close(GEO_OBJ);
    unlink $GEOGRAFIC_COORDINATES;
    rename "temp_geo.data",$GEOGRAFIC_COORDINATES;
    if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
	print "$big_red FATAL ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub eventos_aire <br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub eventos_aire \n\n";
	exit(0);
    }

    if ($red_af1_name ne "") {
	if ($red_af1_captured==0){
	    print HTML_REP "<tr bgcolor=\"#ffdddd\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Lost in  $red_af1_name ($red_af1_lost / $red_af1_kia) </td><td align=\"center\" class=\"ltr80\"><b> -". ($red_af1_lost*$AF_PLANE_LOST_DAM+$red_af1_kia*$AF_PILOT_LOST_DAM). " % </b></td></tr>\n";
	}
	else { # red_af capturado
	    print HTML_REP "<tr bgcolor=\"#ffdddd\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">$red_af1_name now belongs to germany army ($red_af1_lost / $red_af1_kia) </td><td align=\"center\" class=\"ltr80\"><b> N/D </b></td></tr>\n";
	}
    }

    if ($red_af2_name ne "") {
	if ($red_af2_captured==0){
	    print HTML_REP "<tr bgcolor=\"#ffdddd\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Lost in $red_af2_name ($red_af2_lost / $red_af2_kia) </td><td align=\"center\" class=\"ltr80\"><b> -". ($red_af2_lost*$AF_PLANE_LOST_DAM+$red_af2_kia*$AF_PILOT_LOST_DAM) . " % </b></td></tr>\n";
	}
	else { # red_af capturado
	    print HTML_REP "<tr bgcolor=\"#ffdddd\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">$red_af2_name now belongs to german army ($red_af2_lost / $red_af2_kia) </td><td align=\"center\" class=\"ltr80\"><b> N/D </b></td></tr>\n";
	}
    }

    if ($blue_af1_name ne "") {
	if ($blue_af1_captured==0){
	    print HTML_REP "<tr bgcolor=\"#ddddff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Lost in $blue_af1_name ($blue_af1_lost / $blue_af1_kia) </td><td align=\"center\" class=\"ltr80\"><b> -". ($blue_af1_lost*$AF_PLANE_LOST_DAM+$blue_af1_kia*$AF_PILOT_LOST_DAM) ." % </b></td></tr>\n";
	}
	else { # blue_af1 capturado
	    print HTML_REP "<tr bgcolor=\"#ddddff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">$blue_af1_name now belongs to soviet army ($blue_af1_lost / $blue_af1_kia) </td><td align=\"center\" class=\"ltr80\"><b> N/D </b></td></tr>\n";
	}
    }

    if ($blue_af2_name ne "") {
	if ($blue_af2_captured==0){
	    print HTML_REP "<tr bgcolor=\"#ddddff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">Lost in $blue_af2_name ($blue_af2_lost / $blue_af2_kia) </td><td align=\"center\" class=\"ltr80\"><b> -". ($blue_af2_lost*$AF_PLANE_LOST_DAM+$blue_af2_kia*$AF_PILOT_LOST_DAM) ." % </b></td></tr>\n";
	}
	else { # blue_af2 capturado
	    print HTML_REP "<tr bgcolor=\"#ddddff\"><td colspan=\"4\" align=\"center\" class=\"ltr70\">$blue_af2_name now belongs to soviet army ($blue_af2_lost / $blue_af2_kia) </td><td align=\"center\" class=\"ltr80\"><b> N/D </b></td></tr>\n";
	}
    }

    print HTML_REP "</table>\n\n";
    print HTML_REP "</center>\n";

    print MAP_REP1 "</body></html>\n";
    print MAP_REP2 "</body></html>\n";
    print MAP_REP4 "</body></html>\n";
    close(MAP_REP1);
    close(MAP_REP2);
    close(MAP_REP4);
}

sub eventos_tierra(){
    my $i=0;
    my $by;
    my $to;
    my $plane_by;
    my $plane_to;
    my $by_army;
    my $to_army;
    my $letra;
    my $hora;
    my $wasfriend=0;

    #print "\nObjetivos de tierra:\n";

    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3>Ground action:</h3></center>\n\n";
    print HTML_REP "<center>\n  <table border=1>\n";
    print HTML_REP "<tr bgcolor=\"#ffffff\">\n";
    print HTML_REP "  <td class=\"ltr70\">Time</td>\n";
    print HTML_REP "  <td class=\"ltr70\">pilot</td>\n";
    print HTML_REP "  <td class=\"ltr70\">plane/vehicle</td>\n";
    print HTML_REP "  <td class=\"ltr70\">object</td>\n";
    print HTML_REP "</tr>\n";

    my $cx;
    my $cy;
    my $staobj;

    seek LOG, 0, 0;
    while(<LOG>) {
	if ($_=~  m/([0-9:]+) ([^ ]+) destroyed by ([^ ]+) at ([^ ]+) ([^ ]+)/){ 
	    $hora=$1;
	    $staobj=$2;
	    $cx=$4;
	    $cy=$5;

	    ($to,$to_army)=get_name($2);
	    ($plane_to,$to_army)=get_plane($2);
	    ($by,$by_army)=get_name($3);
	    ($plane_by,$by_army)=get_plane($3);
	    #print "$1 $by  $plane_by destruye a $to  $plane_to\n";
	    my $html_by=$by;
	    my $html_to=$to;
	    $html_by =~ s/(.*)<(.*)/$1&lt;$2/; #algunos nombres son incompatibles con html <
	    $html_by =~ s/(.*)>(.*)/$1&gt;$2/;
	    $html_to =~ s/(.*)<(.*)/$1&lt;$2/; #algunos nombres son incompatibles con html <
	    $html_to =~ s/(.*)>(.*)/$1&gt;$2/;
	    $i++;
	    if (($i/2)-int($i/2)){print HTML_REP "<tr bgcolor=\"#ccffcc\">";}
	    else {print HTML_REP "<tr bgcolor=\"#cceedd\">\n";}
	    if ($by_army==$to_army) { $letra="ltr70R"; $wasfriend=1;}
	    else { $letra="ltr70"; $wasfriend=0;}
	    print HTML_REP "  <td class=\"$letra\">$hora</td>\n";
	    print HTML_REP "  <td class=\"$letra\">$html_by</td>\n";
	    print HTML_REP "  <td class=\"$letra\">$plane_by</td>\n";
	    print HTML_REP "  <td class=\"$letra\">$plane_to</td>\n";
	    print HTML_REP "</tr>\n";

	    #db table badc_grnd_event;
	    #       misnum	       VARCHAR(30),
	    #       misrep	       VARCHAR(30),
	    #       hlkiller	       VARCHAR(30) BINARY ,
	    #       plane_killer       VARCHAR(60),
	    #       objkilled	       VARCHAR(30),
	    #       wasfriend          CHAR(3),
	    $dbh->do("INSERT INTO $ground_events_tbl VALUES (?,?,?,?,?,?)",undef,$MIS_TO_REP,("rep".$ext_rep_nbr.".html"),$by,$plane_by,$plane_to,$wasfriend);

	    # verificacion de congruencia  obj estaticos

	    seek MIS, 0, 0;
	    while(<MIS>) {
		if ($_ =~ m/^$staobj [^\$ ]+\$[^ ]+ [12] ([^ ]+) ([0-9.]+)/){
		  if(distance($cx,$cy,$1,$2)>2){
		      print PAR_LOG " $MIS_TO_REP WARNING: obj $staobj displ: ".distance($cx,$cy,$1,$2)." mts cord: $cx $cy $1 $2\n";
		      $warnings++;
		  }
		}
	    }

	}
    }
    print HTML_REP "</table>\n</center>\n\n\n";
}



sub read_mis_details(){
    seek DET, 0, 0;
    while(<DET>) {
	if ($_ =~ m/MAP_NAME_LOAD=(.*)$/) {$MAP_NAME_LOAD=$1;}
	if ($_ =~ m/MAP_NAME_LONG=(.*)$/) {$MAP_NAME_LONG=$1;}
	if ($_ =~ m/ZipCode=([-A-Za-z0-9_]+)/){$ZipCode=$1;}
	if ($_ =~ m/RED_ATTK_TACTIC=1/){$RED_ATTK_TACTIC=1;}
	if ($_ =~ m/BLUE_ATTK_TACTIC=1/){$BLUE_ATTK_TACTIC=1;}
	if ($_ =~ m/RED_RECON=1/){$RED_RECON=1;}
	if ($_ =~ m/BLUE_RECON=1/){$BLUE_RECON=1;}
	if ($_ =~ m/RED_SUM=1/){$RED_SUM=1;}
	if ($_ =~ m/BLUE_SUM=1/){$BLUE_SUM=1;}
	if ($_ =~ m/RED_SUM_AI=([0-9]+)/){$RED_SUM_AI=$1;} # 0 o cantidad de aviones ai en suply
	if ($_ =~ m/BLUE_SUM_AI=([0-9]+)/){$BLUE_SUM_AI=$1;} # 0 o cantidad de aviones ai en suply
	if ($_ =~ m/RED_SUM_AI_LAND=(.*)$/){$RED_SUM_AI_LAND=$1;} # AFCODE de donde aterrizan
	if ($_ =~ m/BLUE_SUM_AI_LAND=(.*)$/){$BLUE_SUM_AI_LAND=$1;} # AFCODE de donde aterrizan
	if ($_ =~ m/RED_SUM_TIME=([0-9]+)/){$RED_SUM_TIME=$1;}
	if ($_ =~ m/BLUE_SUM_TIME=([0-9]+)/){$BLUE_SUM_TIME=$1;}
	if ($_ =~ m/red_tgt_code=([-A-Za-z0-9]+)/) {$red_tgt_code=$1;}
	if ($_ =~ m/blue_tgt_code=([-A-Za-z0-9]+)/) {$blue_tgt_code=$1;}
	if ($_ =~ m/red_target=([-A-Za-z0-9]+)/) {$red_target=$1;}
	if ($_ =~ m/blue_target=([-A-Za-z0-9]+)/) {$blue_target=$1;}
	if ($_ =~ m/red_tgtcx=([0-9]+)/) {$red_tgtcx=$1;}
	if ($_ =~ m/red_tgtcy=([0-9]+)/) {$red_tgtcy=$1;}
	if ($_ =~ m/blue_tgtcx=([0-9]+)/) {$blue_tgtcx=$1;}
	if ($_ =~ m/blue_tgtcy=([0-9]+)/) {$blue_tgtcy=$1;}
	if ($_ =~ m/red_objects=([0-9]+)/) {$red_objects=$1;}
	if ($_ =~ m/blue_objects=([0-9]+)/) {$blue_objects=$1;}
	if ($_ =~ m/red_af1_code=(.*)$/) {$red_af1_code=$1;}
	if ($_ =~ m/red_af2_code=(.*)$/) {$red_af2_code=$1;}
	if ($_ =~ m/blue_af1_code=(.*)$/) {$blue_af1_code=$1;}
	if ($_ =~ m/blue_af2_code=(.*)$/) {$blue_af2_code=$1;}

	if ($red_af1_code eq $red_af2_code) { $red_af2_code="NO MATCH";}
	if ($blue_af1_code eq $blue_af2_code) { $blue_af2_code="NO MATCH";}

	if ($_ =~ m/mission time=(.*)$/) {$mission_time=$1;}

	if ($_ =~ m/Download=(.*)$/) {
	    $Download=$1;
	    $Download=~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
	    $Download=~ s/(.*)>(.*)/$1&gt;$2/g;
	}
	if ($_ =~ m/Redhost=(.*)$/) {
	    $Redhost=$1;
	    $Redhost=~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
	    $Redhost=~ s/(.*)>(.*)/$1&gt;$2/g;
	}
	if ($_ =~ m/Bluehost=(.*)$/) {
	    $Bluehost=$1;
	    $Bluehost=~ s/(.*)<(.*)/$1&lt;$2/g; #algunos nombres son incompatibles con html <
	    $Bluehost=~ s/(.*)>(.*)/$1&gt;$2/g;
	}
	if ($Redhost eq $Download){
	    $Redhost.=" (H)";
	}
	if ($Bluehost eq $Download){
	    $Bluehost.=" (H)";
	}

	if ($_ =~ m/^time=([-A-Za-z0-9: \t]+)/) {$gen_time=$1;}
	if ($_ =~ m/rep_time=([-A-Za-z0-9: ]+)/) {$rep_time=$1;}
	if ($_ =~ m/cloud_type=([-a-zA-Z0-9]+)/) {$cloud_type=$1;}
    }
    $rep_time=scalar(localtime(time));
    print DET "rep_time=$rep_time \n";

    seek MIS,0,0;
    while(<MIS>) {
	if ($_ =~ m/CloudType ([0-9])/) {
	    if ($1==0) {$clima_mision="Clear";}
	    if ($1==1) {$clima_mision="Good";}
	    if ($1==2) {$clima_mision="Tipo 2 - no usado";}
	    if ($1==3) {$clima_mision="Tipo 3 - no usado";}
	    if ($1==4) {$clima_mision="Low visibility";}
	    if ($1==5) {$clima_mision="Precipitations";}
	    if ($1==6) {$clima_mision="Storm";}
	    print DET "clima_mision=$clima_mision \n";
	    last;
	}
    }
}


sub print_mis_objetive_result(){
    my $redchf=0;
    my $tank_killed=0;
    my $tank_dead_limit;
    my $obj_kill=0;
    my $obj_army;

    if ($unix_cgi){ 
	#print "Mission Result:\n\n";
    }

    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3><a href=\"#reports\">View pilot reports</a></h3></center>\n\n";

    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3>Mission Result:</h3></center>\n\n";
    print HTML_REP "<center>\n  <table border=1>\n";

    if ($RED_ATTK_TACTIC==1){
	if ($unix_cgi){ 
	#    print "Soviet Tactic Attack \n";
	}
	print HTML_REP "  <tr bgcolor=\"#eeaaaa\"><td><center><strong>Soviet tactic attack</strong></center></td></tr>\n";
    }

    if ($RED_SUM==1){
	if ($unix_cgi){ 
	#    print "Soviet resuply mission\n";
	}
	print HTML_REP "  <tr bgcolor=\"#eeaaaa\"><td><center><strong>Soviet resuply mission</strong></center></td></tr>\n";
    }

    if ($RED_ATTK_TACTIC==0 && $RED_RECON==0 && $RED_SUM==0){
	if ($unix_cgi){ 
	#    print "Soviet Startegic attack\n";
	}
	print HTML_REP "  <tr bgcolor=\"#eeaaaa\"><td><center><strong>Soviet Startegic attack</strong></center></td></tr>\n";
    }

    print HTML_REP "  <tr bgcolor=\"#ffcccc\"><td>\n";


    if ($RED_ATTK_TACTIC==1){
	$redchf++;
	$tank_dead_limit=7; # default: matan 8 taques y no se gana el sector


	seek GEO_OBJ, 0, 0;
	while(<GEO_OBJ>) {
	    # SEC-Q04,sector--Q04,165000,35000,30,1:1
	    if ($_ =~ m/[^,]+,$red_target,[^,]+,[^,]+,([^,]+),([01]):2/){ # sector atacado azul 
		if ($2==1 || $1>=$TTL_SUPPLYED) { # CON suministro
		    $tank_dead_limit=4; # matan 5 taques y no se gana el sector
		} 
		last;
	    }
	}
	
	seek LOG, 0, 0;
	while(<LOG>) {
	    if ($_=~  m/([0-9:]+) [012]_Chief[0-9] destroyed by ([^ ]+) at ([^ ]+) ([^ ]+)/){
		if ( (get_segundos($1)-get_segundos($stime_str))  <= 2400 ){ # 40 minutos
		    ($by,$obj_army)=get_name($2);
		    ($plane_by,$obj_army)=get_plane($2);
		    if ($unix_cgi){ 
			#print "    $1 - Tank destroyed by  $by $plane_by\n";
		    }
		    print HTML_REP  "    $1 - Tank destroyed by $by $plane_by <br>\n";
		    $tank_killed++;
		}
	    }
	}	
	if ($tank_killed>$tank_dead_limit) {
	    if ($unix_cgi){ 
		#print "    --- Soviets fail to capture $red_target\n";
	    }
	    print HTML_REP "    --- <strong>Soviets fail to capture $red_target</strong>.<br>\n";
	    $red_result="fail"; # para mis_prog_tbl
	}
	else { 
	    $RED_CAPTURA=1;
	    if ($unix_cgi){ 
		#print "    --- Soviets capture $red_target\n";
	    }
	    print HTML_REP  "    --- <strong>Soviets capture  $red_target</strong>.<br>\n";
	    $red_result="capture"; # para mis_prog_tbl
	}
    }
   
    if ($RED_SUM==1 && $RED_SUM_AI==0){ 
	$red_resuply=0;
	my $player_task;
	# @pilot_list[][$hlname,$plane,$seat,$pos,$wing,$army]
	for ($i=0 ; $i<$hpilots; $i++){ # lista pilotos
	    if($pilot_list[$i][5]==1){ # si el piloto es rojo
		$player_task=$pilot_list[$i][6];
		if ($player_task eq "SUM" && $pilot_list[$i][3] !~ m/"Art"/){ # si es un transport y no es artillero
		    my $smoke_count=0;
		    seek LOG, 0, 0;
		    while(<LOG>) {
			if ($_=~  m/[^ ]+ $pilot_list[$i][1] turned wingtip smokes on at ([^ ]+) ([^ ]+)/){
			    $smoke_count++;
			    if (distance($red_tgtcx,$red_tgtcy,$1,$2)<10000 && $smoke_count<4){
				while(<LOG>) {
				    if ($_=~  m/([^ ]+) $pilot_list[$i][1] landed at ([^ ]+) ([^ ]+)/ &&
					( ( (get_segundos($1)-get_segundos($stime_str)) /60 ) <= $RED_SUM_TIME ) 
					&& $smoke_count<4 ){
					my $rpilot_succ=(int(rand(3))+5); # B25: 5 a 7 recover
					if ($unix_cgi){ 
					#    print "    - $pilot_list[$i][0] suply $red_sum_city ($rpilot_succ %) ";
					}
					print HTML_REP  "    - $pilot_list[$i][0] suply $red_sum_city ($rpilot_succ %) ";
					$red_resuply+=$rpilot_succ;
					my $red_land_x=$2;
					my $red_land_y=$3;
					$smoke_count=4; # evitar multiples resuply

					seek GEO_OBJ, 0, 0;
					while(<GEO_OBJ>) {
					    #AF02     ,ae-C12 ,22007.6,1156.7 , 2   , -C  , 12  ,  2  , 24.6  :2
					    if ($_ =~ m/^AF[0-9]{2},([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):1/){ 
						if ($4<=100 && distance($2,$3,$red_land_x,$red_land_y)<2000) {
				                    if ($unix_cgi){ 
							#print " and $1 (".2*$AF_SUM." %)";
						    }
						    print HTML_REP  " and $1 (".2*$AF_SUM." %)";
						    push (@af_resup,$1);
						}
					    }
					}
					if ($unix_cgi){ 
					#    print "\n";
					}
					print HTML_REP  "<br>\n";
				    }
				}
			    }
			}
		    }
		}
	    }
	}
	if ($unix_cgi){ 
	#    print "Soviets resuply  $red_resuply % $red_sum_city \n";
	}
	print HTML_REP "    --- <strong>Soviets resuply  $red_resuply % $red_sum_city </strong>.<br>\n";
	$red_result="$red_resuply"; # para mis_prog_tbl
    }
    
    if ($RED_SUM==1 && $RED_SUM_AI>0){
	my $sourvive = get_task_perc_sorvive(1,"SUM");
	my $city_recover = int($RED_SUM_AI * 3 * $sourvive/100);
	$red_resuply=0;
	for (my $r=0; $r<$city_recover ; $r+=3){
	    $red_resuply+=3;
	}
	if ($unix_cgi){
	    #print "    - AI Suply Group of $RED_SUM_AI planes to $red_sum_city. \n";
	    #print "    - Sourvived : $sourvive % \n";
	    #print "    --- Soviets resuply  $red_resuply % $red_sum_city ";
	}
	print HTML_REP "    - AI Suply Group of $RED_SUM_AI planes to $red_sum_city. <br>\n";
	print HTML_REP "    - Sourvived : $sourvive % <br>\n";
	print HTML_REP "    --- <strong>Soviets resuply  $red_resuply % $red_sum_city ";
	$red_result="$red_resuply"; # para mis_prog_tbl

	my $ai_land_at="";
	seek GEO_OBJ, 0, 0;
	while(<GEO_OBJ>) {
	    if ($_ =~ m/^$RED_SUM_AI_LAND,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^:]+:1/){ 
		$ai_land_at=$1;
		last;
	    }
	}

	my $af_recover= int($RED_SUM_AI * 5 * $sourvive/100);
	if ($ai_land_at ne ""){
	    my $recover=0;
	    for (my $r=0; $r<$af_recover ; $r+=$AF_SUM){
		push (@af_resup,$ai_land_at);
		$recover+=$AF_SUM;
	    }
	    if ($unix_cgi){ 
		#print " and $ai_land_at $recover %";
	    }
	    print HTML_REP  " and $ai_land_at $recover %";
	}
	if ($unix_cgi){ 
	#    print "\n";
	}
	print HTML_REP  " </strong>.<br>\n";
    } 

    if ($RED_ATTK_TACTIC==0 && $RED_RECON==0 && $RED_SUM==0){
	$blue_damage=0;
	$obj_kill=0;
	seek LOG, 0, 0;
	while(<LOG>) {
	    if ($_=~  m/[0-9:]+ [0-9]+_Static destroyed by [^ ]+ at ([^ ]+) ([^ ]+)/){
		if (distance($red_tgtcx,$red_tgtcy,$1,$2)<2000){
		    $obj_kill++;
		}
	    }
	}
	if ($blue_objects==0){
	    print PAR_LOG " $MIS_TO_REP ERROR: 0 blue objects\n";
	    $warnings++;
	}
	else {
	    if ($obj_kill>$blue_objects){
		print PAR_LOG " $MIS_TO_REP WARNING: More blue objects destroyed than placed \n";
		$warnings++;
	    }
	    $blue_damage=(int($obj_kill/$blue_objects*100))/5 ; # maximo da~no = 20% solo un decimal
	    if ($red_tgt_code =~ m/CT/) {
		$blue_damage = (int($blue_damage * 15))/10; # extendemos los da�os a 30%
	    }
	}
	if ($unix_cgi){ 
	#    print  "    VVS destroy $obj_kill ground objetives, in an area with $blue_objects objetives.\n";
	}
	if ($unix_cgi){ 
	    #print  "    The estimated damage in $red_target is  ".$blue_damage."%.\n";
	}
	print HTML_REP "    VVS destroy $obj_kill ground objetives, in an area with $blue_objects objetives.<br>\n";
	print HTML_REP "    The estimated damage in $red_target is <strong>".$blue_damage."%.</strong><br>\n";
	$red_result="$blue_damage"; # para mis_prog_tbl
    }
    
    print HTML_REP "  </td></tr>\n\n";
    print HTML_REP "  <tr bgcolor=\"#ffffcc\"><td colspan=1></td></tr>\n\n"; # separador vvs/okl
    
    if ($BLUE_ATTK_TACTIC==1){
	if ($unix_cgi){ 
	#    print "German Tactical attack\n";
	}
	print HTML_REP "  <tr bgcolor=\"#aaaaee\"><td><center><strong>German tactical attack</strong></center></td></tr>\n";
    }

    if ($BLUE_SUM==1){
	if ($unix_cgi){ 
	#    print "German suply mission\n";
	}
	print HTML_REP "  <tr bgcolor=\"#aaaaee\"><td><center><strong>German suply mission</strong></center></td></tr>\n";
    }

    if ($BLUE_ATTK_TACTIC==0 && $BLUE_RECON==0 && $BLUE_SUM==0){
	if ($unix_cgi){ 
	#    print "German stategic attack:\n";
	}
	print HTML_REP "  <tr bgcolor=\"#aaaaee\"><td><center><strong>German Strategic attack:</strong></center></td></tr>\n";
    }
    
    print HTML_REP "  <tr bgcolor=\"#ccccff\"><td>\n";
    
    if ($BLUE_ATTK_TACTIC==1){
	$tank_killed=0;
	$tank_dead_limit=7; # defaulf: matan 8 taques y no se gana el sector

	if ($redchf) {$bchf="345";} # guarda check asd cambiar . pre-supone que siempre hay 3 grupos de tanques - CAMBIAR
	else {$bchf="012";}
	

	seek GEO_OBJ, 0, 0;
	while(<GEO_OBJ>) {
	    # SEC-Q04,sector--Q04,165000,35000,30,1:1
	    if ($_ =~ m/^[^ ]+,$blue_target,[^,]+,[^,]+,([^,]+),([01]):1/){ # sector atacado rojo 
		if ($2==1 || $1 >= $TTL_SUPPLYED ) { # CON suministro
		    $tank_dead_limit=4; # matan 5 taques y no se gana el sector
		} 
		last;
	    }
	}
	
	seek LOG, 0, 0;
	while(<LOG>) {
	    if ($_=~  m/([0-9:]+) [$bchf]_Chief[0-9] destroyed by ([^ ]+) at ([^ ]+) ([^ ]+)/){
		if ( (get_segundos($1)-get_segundos($stime_str))  <= 2400 ){ # 40 minutos
		    ($by,$obj_army)=get_name($2);
		    ($plane_by,$obj_army)=get_plane($2);
		    if ($unix_cgi){ 
			#print "    $1 - Tank destroyed by  $by $plane_by\n";
		    }
		    print HTML_REP  "    $1 - Tank destroyed by $by $plane_by<br>\n";
		    $tank_killed++;
		}
	    }
	}
	if ($tank_killed>$tank_dead_limit) {
	    if ($unix_cgi){ 
		#print "    --- Germans fail to capture $blue_target\n";
	    }
	    print HTML_REP "    --- <strong>Germans fail to capture $blue_target</strong>.<br>\n";
	    $blue_result="fail"; # para mis_prog_tbl
	}
	else { 
	    $BLUE_CAPTURA=1;
	    if ($unix_cgi){ 
		#print "    --- Germans capture $blue_target\n";
	    }
	    print HTML_REP "    --- <strong>Germans capture $blue_target</strong>.<br>\n";
	    $blue_result="capture"; # para mis_prog_tbl
	}
    }


    if ($BLUE_SUM==1 && $BLUE_SUM_AI==0){ 
	$blue_resuply=0;
	my $player_task;
	# @pilot_list[][$hlname,$plane,$seat,$pos,$wing,$army]
	for ($i=0 ; $i<$hpilots; $i++){ # lista pilotos
	    if($pilot_list[$i][5]==2){ # si el piloto es azul
		$player_task=$pilot_list[$i][6];
		if ($player_task eq "SUM"){ # si es un transport
		    my $smoke_count=0;
		    seek LOG, 0, 0;
		    while(<LOG>) {
			if ($_=~  m/[^ ]+ $pilot_list[$i][1] turned wingtip smokes on at ([^ ]+) ([^ ]+)/){
			    $smoke_count++;
			    if (distance($blue_tgtcx,$blue_tgtcy,$1,$2)<10000 && $smoke_count<3){
				while(<LOG>) {
				    if ($_=~  m/([^ ]+) $pilot_list[$i][1] landed at ([^ ]+) ([^ ]+)/ &&
					( ( (get_segundos($1)-get_segundos($stime_str)) /60 ) <= $BLUE_SUM_TIME )
					&& $smoke_count<4 ){
					my $bpilot_succ=(int(rand(3))+5); # He-111: 5 a 7 recover
					if ($unix_cgi){ 
					    #print "    - $pilot_list[$i][0] suply $blue_sum_city ($bpilot_succ %)\n";
					}
					print HTML_REP  "    - $pilot_list[$i][0] suply $blue_sum_city ($bpilot_succ %)\n";
					$blue_resuply+=$bpilot_succ;
					my $blue_land_x=$2;
					my $blue_land_y=$3;
					$smoke_count=4; # evitar multiples resuply

					seek GEO_OBJ, 0, 0;
					while(<GEO_OBJ>) {
					    #AF02      ,ae-C12 ,22007.6,1156.71,2    ,   -C,   12,    2, 24.6  :2
					    if ($_ =~ m/^AF[0-9]{2},([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):2/){ 
						if ($4<=100 && distance($2,$3,$blue_land_x,$blue_land_y)<2000) {
						    if ($unix_cgi){ 
							#print " and $1 (".2*$AF_SUM." %)";
						    }
						    print HTML_REP  " and $1 (".2*$AF_SUM." %)";
						    push (@af_resup,$1);
						}
					    }
					}
					if ($unix_cgi){ 
					#    print "<br>\n";
					}
					print HTML_REP  "<br>\n";
				    }
				}
			    }
			}
		    }
		}
	    }
	}
	if ($unix_cgi){ 
	#    print "Germans resuply  $blue_resuply % $blue_sum_city\n";
	}
	print HTML_REP "    --- <strong>Germans resuply  $blue_resuply % $blue_sum_city </strong>.<br>\n";
	$blue_result="$blue_resuply"; # para mis_prog_tbl
    }

    if ($BLUE_SUM==1 && $BLUE_SUM_AI>0){
	my $sourvive = get_task_perc_sorvive(2,"SUM");
	my $city_recover = int($BLUE_SUM_AI * 3 * $sourvive/100);
	$blue_resuply=0;
	for (my $r=0; $r<$city_recover ; $r+=3){
	    $blue_resuply+=3;
	}
	if ($unix_cgi){
	    #print "    - AI Suply Group of $BLUE_SUM_AI planes to $blue_sum_city. \n";
	    #print "    - Sourvived : $sourvive % \n";
	    #print "    --- Germans resuply  $blue_resuply % $blue_sum_city ";
	}
	print HTML_REP "    - AI Suply Group of $BLUE_SUM_AI planes to $blue_sum_city. <br>\n";
	print HTML_REP "    - Sourvived : $sourvive % <br>\n";
	print HTML_REP "    --- <strong>Germans resuply  $blue_resuply % $blue_sum_city \n";
	$blue_result="$blue_resuply"; # para mis_prog_tbl

	my $ai_land_at="";
	seek GEO_OBJ, 0, 0;
	while(<GEO_OBJ>) {
	    if ($_ =~ m/^$BLUE_SUM_AI_LAND,([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^:]+:2/){ 
		$ai_land_at=$1;
		last;
	    }
	}
	my $af_recover= int($BLUE_SUM_AI * 5 * $sourvive/100);
	if ($ai_land_at ne ""){
	    my $recover=0;
	    for (my $r=0; $r<$af_recover ; $r+=$AF_SUM){
		push (@af_resup,$ai_land_at);
		$recover+=$AF_SUM;
	    }
	    if ($unix_cgi){ 
		#print " and $ai_land_at $recover %";
	    }
	    print HTML_REP  " and $ai_land_at $recover %";
	}
	if ($unix_cgi){ 
	#    print "\n";
	}
	print HTML_REP  " </strong>.<br>\n";

    } 


    if ($BLUE_ATTK_TACTIC==0 && $BLUE_RECON==0 && $BLUE_SUM==0){
	$red_damage=0;
	$obj_kill=0;
	seek LOG, 0, 0;
	while(<LOG>) {
	    if ($_=~  m/[0-9:]+ [0-9]+_Static destroyed by [^ ]+ at ([^ ]+) ([^ ]+)/){
		if (distance($blue_tgtcx,$blue_tgtcy,$1,$2)<2000){
		    $obj_kill++;
		}
	    }
	}
	if ($red_objects==0){
	    print PAR_LOG " $MIS_TO_REP ERROR: 0 red objets\n";
	    $warnings++;
	}
	else {
	    if ($obj_kill>$red_objects ){
		print PAR_LOG " $MIS_TO_REP WARNING: More red objects destroyed  than placed \n";
		$warnings++;
	    }
	    $red_damage=(int($obj_kill/$red_objects*100))/5 ; # maximo da~no = 20% solo un decimal
	    if ($blue_tgt_code =~ m/CT/) {
		$red_damage = (int($red_damage * 15))/10; # extendemos los da�os a 30%
	    }
	}
	if ($unix_cgi){ 
	#    print "    LW destroy $obj_kill ground objetives, in an area with $red_objects objetives.\n";
	}
	if ($unix_cgi){ 
	#    print "    The estimated damage in $blue_target is ".$red_damage."%.\n";
	}
	print HTML_REP "    LW destroy $obj_kill ground ovjetives, in an area with $red_objects objetives.<br>\n";
	print HTML_REP "    The estimated damage in $blue_target is <strong>".$red_damage."%.</strong>\n";
	$blue_result="$red_damage"; # para mis_prog_tbl
    }
    print HTML_REP "  </td></tr>\n  </table>\n</center>\n\n\n";
}


sub look_af_and_ct() {
    open (TEMPGEO, ">temp_geo.data"); #
    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) {
	if ($_ !~ m/^($red_tgt_code,|$blue_tgt_code,)/) { # si no es una line que nos interesa...
	    print TEMPGEO;
	}
	else { 
	    if ($_ =~ m/^SEC/ || $_ =~ m/^SUC/ ) { # si las lines son  SEC o SUC, los imprimimos, nada que hacer
		print TEMPGEO;
	    }
	    if ($_ =~ m/^$red_tgt_code/ && $red_tgt_code =~ m/AF/) { # si rojo ataca un af rojo... buscamos  solo af azul
		if ($_ =~ m/^$red_tgt_code,.*,([^:]+):2/){ 
		    $new_dam=$blue_damage; 
		    $dam=$1+$new_dam;
		    if ($dam>100) {$dam=100;}
		}
		if ($_ =~ s/^($red_tgt_code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:2/$1,$dam:2/){ 
		    #print "red ataco AF azul\n"; # debug sacar
		    print TEMPGEO;
		}
		else { 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$blue_tgt_code/ && $blue_tgt_code =~ m/AF/) { # si azul ataca un af rojo...buscamos solo af  rojos
		if ($_ =~ m/^$blue_tgt_code,.*,([^:]+):1/){
		    $new_dam=$red_damage;
		    $dam=$1+$new_dam;
		    if ($dam>100) {$dam=100;}
		}
		if ($_ =~ s/^($blue_tgt_code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+:1/$1,$dam:1/){ #revisar
		    #print "blue ataco AF roja\n"; # debug sacar
		    print TEMPGEO;
		}
		else { 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$red_tgt_code/ && $red_tgt_code =~ m/^CT/){
		if ($_ =~ m/^$red_tgt_code,[^,]+,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,([^,]+),[^,]+:2/){ #buscar solo ciud azules
		    $new_dam=$blue_damage;
		    $dam=$2+$new_dam; # en el futuro incorporar 2 decimales
		    if ($dam>100){$dam=100;}
		    $rad_und=$1;
		    $sup_rad=int($1 * (1-$dam/100));
		    $_ =~ s/^($red_tgt_code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),([^,]+),([^,]+):2/$1,$dam,$sup_rad:2/;
		    #print"red ataco ciudad azul\n"; # debug sacar
		    print TEMPGEO;
		}
		else { 
		    print TEMPGEO;
		}
	    }
	    if ($_ =~ m/^$blue_tgt_code/ && $blue_tgt_code =~ m/^CT/) {
		if ($_ =~ m/^$blue_tgt_code,[^,]+,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,([^,]+),[^,]+:1/){ #buscar solo ciud rojas
		    $new_dam=$red_damage;
		    $dam=$2+$new_dam;  # en el futuro incorporar 2 decimales
		    if ($dam>100){$dam=100;}
		    $rad_und=$1;
		    $sup_rad=int($1 * (1-$dam/100));
		    $_ =~ s/^($blue_tgt_code,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),([^,]+),([^,]+):1/$1,$dam,$sup_rad:1/;
		    #print "blue ataco ciudad roja\n"; # debug sacar
		    print TEMPGEO;
		}
		else { 
		    print TEMPGEO;
		}
	    }
	}
    }
    close(TEMPGEO);
    close(GEO_OBJ);
    unlink $GEOGRAFIC_COORDINATES;
    rename "temp_geo.data",$GEOGRAFIC_COORDINATES;
    if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
	print "$big_red FATAL ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub look_af_and_ct <br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub look_af_and_ct \n\n";
	exit(0);
    }
}



sub look_resuply() {
    open (TEMPGEO, ">temp_geo.data"); #
    seek GEO_OBJ, 0, 0;
    my $armada;
    while(<GEO_OBJ>) {
	if ($_ !~ m/^CT[0-9]{2},($blue_sum_city,|$red_sum_city,)/) { # si no es una line que nos interesa...
	    if ($_ =~ m/^AF[0-9]{2},([^,]+),.*,([^:]+):([12])/){
		my $line_in=$_;
		my $looking_af=$1;
		my $dam=$2;
		my $army=$3;
		my $af_dam_diff=0;
		foreach $af_in (@af_resup) {
		    if ($af_in eq $looking_af){
			$af_dam_diff+=$AF_SUM;
		    }
		}
		if ($army==1 && $RED_SUM_AI==0) {$af_dam_diff*=2;}  # double recovery if human suply
		if ($army==2 && $BLUE_SUM_AI==0) {$af_dam_diff*=2;} # double recovery if human suply
		$dam-=$af_dam_diff;
		if ($dam<0) {$dam=0;}
		$line_in =~ s/^([^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^:]+:[12]/$1,$dam:$army/; 
		print TEMPGEO $line_in;
	    }
	    else {
		print TEMPGEO;
	    }
	}
	else { #CT00,LLovlya,65000,145000,50,2,3,6.4,46:1
	    if ($_ =~ m/^CT[0-9]+,$blue_sum_city,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,([^,]+),[^,]+:([12])/){
		$rad_und=$1;
		$new_dam=$blue_resuply;
		$dam=$2-$new_dam; # en el futuro incorporar 2 decimales
		$armada=$3; # esto es porque army pudo haber cambiado mientras se volaba esta mision
		if ($dam<0) {
		    $dam=0; 
		    $rad_und=int($rad_und * 1.1);
		    if ($rad_und>40) {$rad_und=40;} # radio maximo para las ciudades : 40 km
		}
		$sup_rad=int($rad_und * (1-$dam/100));
		$_ =~ s/^([^,]+,$blue_sum_city,[^,]+,[^,]+),[^,]+,([^,]+,[^,]+),[^,]+,[^,]+:2/$1,$rad_und,$2,$dam,$sup_rad:$armada/;

		print TEMPGEO;
	    }
	    if ($_ =~ m/^CT[0-9]+,$red_sum_city,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,([^,]+),[^,]+:([12])/){ 
		$rad_und=$1;
		$new_dam=$red_resuply;
		$dam=$2-$new_dam; # en el futuro incorporar 2 decimales
		$armada=$3; # esto es porque army pudo haber cambiado mientras se volaba esta mision
		if ($dam<0) {
		    $dam=0; 
		    $rad_und=int($rad_und * 1.1);
		    if ($rad_und>40) {$rad_und=40;} # radio maximo para las ciudades : 40 km
		}
		$sup_rad=int($rad_und * (1-$dam/100));
		$_ =~ s/^([^,]+,$red_sum_city,[^,]+,[^,]+),[^,]+,([^,]+,[^,]+),[^,]+,[^,]+:1/$1,$rad_und,$2,$dam,$sup_rad:$armada/;
		print TEMPGEO;
	    }
	}
    }
    close(TEMPGEO);
    close(GEO_OBJ);
    unlink $GEOGRAFIC_COORDINATES;
    rename "temp_geo.data",$GEOGRAFIC_COORDINATES;
    if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
	print "$big_red FATAL ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub look_resuply <br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub look_resuply\n\n";
	exit(0);
    }
}



sub look_sectors(){

#    if ($unix_cgi){  print "\nComputing new front line ... ";}

    my $line_back;
    seek FRONT,0,0;
    my $fl_ver = readline(FRONT);  #
    $fl_ver =~ s/^[^=]+=([0-9]+)$/$1/; #
    open (TEMPFL, ">temp_fl.data"); #
    print TEMPFL "FRONT_LINE_VERSION=";
    printf TEMPFL ("%05.0f\n",$fl_ver+1); 
    
    while(<FRONT>) {
	if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([12])/){
	    if ( ($RED_ATTK_TACTIC==1) && ($RED_CAPTURA==1) && ($3==2) && 
		 (distance($red_tgtcx,$red_tgtcy,$1,$2) < 3000)) {
		$_ =~ s/(FrontMarker[0-9]?[0-9]?[0-9] [^ ]+ [^ ]+) 2/$1 1/;
		#print "red captures sector<br>"; #debug sacar
	    }
	    if ( ($BLUE_ATTK_TACTIC==1) && ($BLUE_CAPTURA==1) && ($3==1) && 
		 (distance($blue_tgtcx,$blue_tgtcy,$1,$2) < 3000)) {
		$_ =~ s/(FrontMarker[0-9]?[0-9]?[0-9] [^ ]+ [^ ]+) 1/$1 2/;
		#print "blue captures sector<br>"; #debug sacar
	    }
	}
	print TEMPFL;
    }
    close(TEMPFL);
    open (TEMPFL, "<temp_fl.data"); #
    close(FRONT);
    unlink $FRONT_LINE;  
    open (FRONT, ">$FRONT_LINE"); #reabrimos
    # busqueda de sectores aislados (por ahora solo imprime el aviso
    seek TEMPFL,0,0;
    while(<TEMPFL>) {
	if ($_ !~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([12])/){
	    print FRONT;
	}
	else {
	    $saved=$_;
	    $fm_cx=$1;
	    $fm_cy=$2;
	    $army=$3;
	    $line_back=tell TEMPFL;                 ##leemso la posicion en el archivo
	    $near=500000; # gran distancia para empezar
	    seek TEMPFL,0,0;
	    while(<TEMPFL>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) $army/){
		    $dist=distance($fm_cx,$fm_cy,$1,$2);
		    if ($dist>0 && $dist<$near){
			$near=$dist;
		    }
		}
	    }
	    if ($near>17000) {
		my @letras=("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"
			 ,"Q","R","S","T","U","V","W","X","Y","Z");
		my $ltr=$letras[int($fm_cx/10000)];
		my $nbr=int($fm_cy/10000)+1;
		if ($army==1){
		    $op=2;
		    push(@red_cap, "$ltr.$nbr");
		}
		else {
		    $op=1;
		    push(@blue_cap, "$ltr.$nbr");
		}
		$saved =~ s/(FrontMarker[0-9]?[0-9]?[0-9] [^ ]+ [^ ]+) $army/$1 $op/;
		print FRONT $saved;
	    }
	    else {
		print FRONT $saved;
	    }
	    seek TEMPFL,$line_back,0; # regrresamos a la misma sig linea
	}
    }
    close(FRONT);
    if (!open (FRONT, "<$FRONT_LINE")){ # reabrimos
	print  "$big_red FATAL ERROR: Can't open $FRONT_LINE: $! on look_sectors (a)<br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $FRONT_LINE: $! on sub look_sectors (a)\n\n"; 
	exit(0);
    }
    close(TEMPFL);
    unlink "temp_fl.data";

    # ahora para cada front marker, miramos si esta sobre un sector con TTL=0
    # y si eso es verdad, colocamos el front marker con el army de la ciudad + cercana
    open (TEMPFL, ">temp_fl.data"); #
    seek FRONT,0,0;
    while(<FRONT>) {
	if ($_ !~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([12])/){
	    print TEMPFL;
	}
	else {
	    $saved=$_;
	    $fm_cx=$1;
	    $fm_cy=$2;
	    $army=$3;
	    my $orig_army=$3;
	    if (  ($BLUE_CAPTURA==1) && ($3==2) && (distance($blue_tgtcx,$blue_tgtcy,$fm_cx,$fm_cy) < 2000)) {
		print TEMPFL;
		next;
	    }
	    if ( ($RED_CAPTURA==1) && ($3==1) &&  (distance($red_tgtcx,$red_tgtcy,$fm_cx,$fm_cy) < 2000)) {
		print TEMPFL;
		next;
	    }
	    seek GEO_OBJ,0,0;
	    while(<GEO_OBJ>) {
		if ($_ =~  m/SEC.{4},[^,]+,([^,]+),([^,]+),0,[^:]+:[12]/ && 		 
		    (distance($fm_cx,$fm_cy,$1,$2) < 2000)) {  # sec cercano a FM con ttl=0
		    
		    $near=500000;
		    seek GEO_OBJ,0,0;
		    while(<GEO_OBJ>) { #buscamos la ciudad mas cercana
	                if ($_ =~ m/^CT[0-9]{2},[^,]+,([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):([12])/) {
			    $dist=distance($fm_cx,$fm_cy,$1,$2);
			    $dist-=(($3*1000)/2); # distance - (suply range)/2
			    if ($dist<$near){
				$near=$dist;
				$army=$4;
			    }
			}		    
		    }
		    if ($orig_army != $army){
			my @letras=("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"
				    ,"Q","R","S","T","U","V","W","X","Y","Z");
			my $ltr=$letras[int($fm_cx/10000)];
			my $nbr=int($fm_cy/10000)+1;
			if ($army==1){
			    push(@red_ttl_recover, "$ltr.$nbr");
			}
			else {
			    push(@blue_ttl_recover, "$ltr.$nbr");
			}

		    }
		    $saved =~ s/(FrontMarker[0-9]?[0-9]?[0-9] [^ ]+ [^ ]+) [12]/$1 $army/;
		}
	    }
	    print TEMPFL $saved;
	}
    }
    close(TEMPFL); # cerramos para renombrar
    close(FRONT); # cerramos para borrar/o hacer nkup
    unlink $FRONT_LINE;  #  backup en lugar de borrar?? si mejor --cambiar CHECK
    rename "temp_fl.data", $FRONT_LINE; ## renombramos
    if (!open (FRONT, "<$FRONT_LINE")) { #reabrimos
	print "$big_red FATAL ERROR: Can't open $FRONT_LINE: $! on sub look_sectors (b)<br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open $FRONT_LINE: $! on sub look_sectors (b)\n\n";
	exit(0);
    }
    #if ($unix_cgi){ print " Front line Updated\n"; } # sacar
    #End cambio FL por ttl=0
}


sub check_geo_file(){

#    if ($unix_cgi){  print "Analyzing map places, based on new front line ...";}

    seek GEO_OBJ,0,0;
    my $geo_ver= readline(GEO_OBJ);  ## CHECK - se requiere que la PRIMER LINEA del file sea la version- mejorar esto!!
    if ($geo_ver !~ m/FRONT_LINE_VERSION/) {
	print "$big_red FATAL ERROR:  No FRONT_LINE_VERSION on $GEOGRAFIC_COORDINATES .<br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Missing FRONT_LINE_VERSION on $GEOGRAFIC_COORDINATES .\n\n";
	exit(0);
    }
    $geo_ver =~ s/^[^=]+=([0-9]+)$/$1/; ## CHECK y si la version tiene letras o aluna mierda??? = revisar!! espacios etc
    
    seek FRONT,0,0;
    my $front_ver= readline(FRONT); ## CHECK se requiere que la PRIMER LINEA del file sea la version- mejorar esto!!
    if ($front_ver !~ m/FRONT_LINE_VERSION/) {
	print "$big_red FATAL ERROR: No FRONT_LINE_VERSION on $FRONT_LINE .<br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Missing FRONT_LINE_VERSION on $FRONT_LINE .\n\n";
	exit(0);
    }
    $front_ver =~ s/^[^=]+=([0-9]+)$/$1/; ## CHECK y si la version tiene letras o aluna mierda??? = revisar!! espacios etc
    
    if ($geo_ver!=$front_ver) { # version de front line no coincide con geografic_data
	my $orig_data;
	my $cxo;
	my $cyo;
	my $army;
	my $near; 
	my $dist;
	open (TEMP, ">temp_geo_obj.data"); # CHECK.. verificar que no exista un temp..._obj.data de otro porceso!!
	print TEMP "FRONT_LINE_VERSION=$front_ver";
	#no seek, estamos justo debajo de la primer linea con FRONT_LINE_VERSION=... CHECK
	while(<GEO_OBJ>) {
	    if ($_ =~  m/(AF.{2}|SEC.{4}|CT[0-9]{2}|SUC[0-9]{2}),[^,]+,([^,]+),([^,]+),[^:]*:([0-2])/) {
		$orig_data=$_;
		$cxo=$2;
		$cyo=$3;
		$army=$4;
		$near=500000; # gran distancia para comenzar (500 km)
		seek FRONT,0,0;
		while(<FRONT>) {
		    if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([0-2])/){
			$dist= distance($cxo,$cyo,$1,$2);
			if ($dist < $near) {
			    $near=$dist;
			    $army=$3;
			}
		    }
		}
		$orig_data =~ s/^([^:]+):[0-3]/$1:$army/;
		print TEMP $orig_data;
	    }
	    else {
		print TEMP $_;
	    }
	}
	close(TEMP); # cerramos para renombrar
	close(GEO_OBJ); # cerramos para borrar/o hacer nkup
	unlink $GEOGRAFIC_COORDINATES;  ##  backup en lugar de borrar?? si mejor --cambiar CHECK
	rename "temp_geo_obj.data", $GEOGRAFIC_COORDINATES; ## renombramos
	if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) { #reabrimos
	    print "$big_red FATAL ERROR: Can't open $GEOGRAFIC_COORDINATES: $! on sub check_geo_file<br>\n";
	    print "Please NOTIFY this error.\n";
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub check_geo_file\n\n"; 
	    exit(0);
	}
#	if ($unix_cgi){ print "<br>";} # sacar
    }
}


sub check_sec_sumin(){
   #para cada ciudad
   #buscar todos los sectores amigo revisando si estan en el radio y actalizar
    my $line_back;
    my $orig_sec;
    my $cx;
    my $cy;
    my $ttl;
    my $army;
    my $state; 

    open (TEMPGEO, ">temp_geo.data"); #
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ !~  m/SEC.{4},[^,]+,([^,]+),([^,]+),([^,]+),[^:]+:([12])/) {
	    print TEMPGEO;
	}
	else {
	    $orig_sec=$_;
	    $cx=$1;
	    $cy=$2;
	    $ttl=$3;
	    $army=$4;
	    $line_back=tell GEO_OBJ;     ##lemos la posicion en el archivo
	    $state=0; # suponemos sector aislado hasta no demostrar los contrario
	    while(<GEO_OBJ>) {
		if ($_ =~  m/CT[0-9]{2},[^,]+,([^,]+),([^,]+),.*,([^:]+):$army/) {
		    if (distance($cx,$cy,$1,$2)<($3*1000)){
			$state=1;
		    }
		}
	    }
	    if ($state==1) {$ttl=30;}
	    else { if ($ttl>0) {$ttl-=1;}}
	    #aqui ver si fue un sector que cambio de manos, poner un ttl de 30
	    if ( ($orig_sec =~ /$red_target/ && $RED_CAPTURA==1)   ||  
		 ($orig_sec =~ /$blue_target/ && $BLUE_CAPTURA==1) ){
		$ttl=30;
	    }
	    
	    $orig_sec =~ s/(SEC.{4},[^,]+,[^,]+,[^,]+),[^,]+,[^:]+:$army/$1,$ttl,$state:$army/;
	    print TEMPGEO $orig_sec;
	    seek GEO_OBJ,$line_back,0; # regresamos a misma linea
	}
    }
    close(TEMPGEO);
    close(GEO_OBJ);
    unlink $GEOGRAFIC_COORDINATES;
    rename "temp_geo.data",$GEOGRAFIC_COORDINATES;
    if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
	print "$big_red FATAL ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub check_sec_sum <br>\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on sub check_sec_sum\n\n";
	exit(0);
    }
}



sub check_day(){
    $ext_rep_nbr =~ m/_([0-9]+)/;
    $rep_count=$1;

    if (($rep_count%$MIS_PER_VDAY) ==0){ 
	print "$MIS_PER_VDAY missions  = NEW DAY\n";
	
	open (TEMPGEO, ">temp_geo.data"); #
	seek GEO_OBJ, 0, 0;
	while(<GEO_OBJ>) {
	    if ($_ !~ m/(^AF[0-9]{2},|^CT[0-9]{2},)/) { # si no es ciudad o AF
		print TEMPGEO;
	    }
	    else { 
		if ($_ =~ m/AF[0-9]{2},.*,([^:]+):[12]/){ 
		    $dam=$1-$AF_VDAY_RECOVER;
		    if ($dam<0) {$dam=0;}
		    $_ =~ s/^(AF[0-9]{2},[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,)([^,]+)(:[12])/$1.$dam.$3/e;
		    print TEMPGEO;
		}
		if ($_ =~ m/CT[0-9]{2}/){ #   ext   cx    cy   rad_und tipo   zon   dam    sup_ra
		    $_ =~ m/^[^,]+,[^,]+,[^,]+,[^,]+,([^,]+),[^,]+,[^,]+,([^,]+),[^,]+:[12]/;
		    $rad_und=$1;
		    $dam=$2;
		    $dam= int(($dam-$CT_VDAY_RECOVER)*100)/100;
		    if ($dam<0){$dam=0;}
		    $sup_rad=int($1 * (1-$dam/100));
		    $_ =~ s/^([^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+),[^,]+,[^,]+:([12])/$1,$dam,$sup_rad:$2/;
		    print TEMPGEO;
		}
	    }
	}
	close(TEMPGEO);
	close(GEO_OBJ);
	unlink $GEOGRAFIC_COORDINATES;
	rename "temp_geo.data",$GEOGRAFIC_COORDINATES;
	if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
	    print "$big_red ERROR Can't open File $GEOGRAFIC_COORDINATES: $! on check_day\n";
	    print "Please NOTIFY this error.\n";
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $GEOGRAFIC_COORDINATES: $! on check_day\n\n";
	    exit(0);
	}
    }
}


sub make_attack_page(){


    my @red_possible=();
    my $line_back;
    ## seleccion de objetivos al azar TACTICOS ROJOS
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/SEC.{4},([^,]+),([^,]+),([^,]+),[^:]*:2.*$/) {
	    $tgt_name=$1;
	    $cxo=$2;
	    $cyo=$3;
	    $near=500000; # gran distancia para comenzar (500 km)
	    $line_back=tell GEO_OBJ;                 ##lemos la posicion en el archivo
	    seek GEO_OBJ,0,0;
	    while(<GEO_OBJ>) {
		if ($_ =~ m/SEC.{4},[^,]+,([^,]+),([^,]+),[^,]+,[^:]+:1/){ #sectores rojos
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist<16000) {
			my $cityname="NONE";
			seek GEO_OBJ,0,0;
			while(<GEO_OBJ>) {
			    if  ($_ =~ m/poblado,([^,]+),$tgt_name/ ) { # si es un sec con city: poblado,Obol,sector--A15
				$cityname=$1;
			    }
			}
			if ($cityname ne "NONE") {
			    seek GEO_OBJ,0,0;
			    while(<GEO_OBJ>) {
				if ( $_ =~ m/^CT[0-9]{2},$cityname,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([^,]+),[^:]+:[12].*$/) {
				    # print "valor da~nos $cityname = $1 \n";
				    if ($1 >50) {
					push (@red_possible,$tgt_name);
					last;
				    }
				}
			    }
			}
			else {
			    push (@red_possible,$tgt_name);
			    last;
			}
		    }
		}
	    }
	    seek GEO_OBJ,$line_back,0; # regrresamos a la misma sig linea	    
	}
    }
    ## seleccion de objetivos al azar ESTARTEGICOS rojos (SOLO AF)
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/(AF.{2}),([^,]+),([^,]+),([^,]+),[^:]*:2.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    $near=500000; # gran distancia para comenzar (500 km)
	    seek FRONT,0,0;
	    while(<FRONT>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) 1/){
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist < $near) {
			$near=$dist;
			if ($dist<40000) {last;}  #version 24 optim change
		    }
		}
	    }
	    if ($near <40000) {
		push (@red_possible,$tgt_name); # los ponemos al final
	    }
	}
    }


    ## seleccion de SUMINISTROS A CIUDADES ROJAS
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/^(SUC[0-9]{2}),([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):1.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    unshift (@red_possible,$tgt_name);
	}
    }


    ## seleccion de objetivos al azar ESTARTEGICOS rojos (SOLO CIUDADES)
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/^(CT[0-9]{2}),([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):2.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    $near=500000; # gran distancia para comenzar (500 km)
	    seek FRONT,0,0;
	    while(<FRONT>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) 1/){
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist < $near) {
			$near=$dist;
			if ($dist<80000) {last;}  #version 24 optim change
		    }
		}
	    }
	    if ($near <80000) {
		unshift (@red_possible,$tgt_name);
	    }
	}
    }


#------------------------------------------------------

    ## seleccion de objetivos al azar TACTICOS AZULES
    my @blue_possible=();
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/SEC.{4},([^,]+),([^,]+),([^,]+),[^:]*:1.*$/) {
	    $tgt_name=$1;
	    $cxo=$2;
	    $cyo=$3;
	    $line_back=tell GEO_OBJ;                 ##lemos la posicion en el archivo
	    seek GEO_OBJ,0,0;
	    while(<GEO_OBJ>) {
		if ($_ =~ m/SEC.{4},[^,]+,([^,]+),([^,]+),[^,]+,[^:]+:2/){ #sectores azules
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist<16000) {
			my $cityname="NONE";
			seek GEO_OBJ,0,0;
			while(<GEO_OBJ>) {
			    if  ($_ =~ m/poblado,([^,]+),$tgt_name/ ) { # si es un sec con city: poblado,Obol,sector--A15
				$cityname=$1;
			    }
			}
			if ($cityname ne "NONE") {
			    seek GEO_OBJ,0,0;
			    while(<GEO_OBJ>) {
				if ( $_ =~ m/^CT[0-9]{2},$cityname,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,([^,]+),[^:]+:[12].*$/) {
				   # print "valor da~nos $cityname = $1 \n";
				    if ($1 >50) {
					push (@blue_possible,$tgt_name);
					last;
				    }
				}
			    }
			}
			else {
			    push (@blue_possible,$tgt_name);
			    last;
			}
		    }
		}
	    }
	    seek GEO_OBJ,$line_back,0; # regrresamos a la misma sig linea	    
	}
    }
    ## seleccion de objetivos al azar ESTARTEGICOS AZULES (SOLO AF)
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/(AF.{2}),([^,]+),([^,]+),([^,]+),[^:]*:1.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    $near=500000; # gran distancia para comenzar (500 km)
	    seek FRONT,0,0;
	    while(<FRONT>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) 2/){
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist < $near) {
			$near=$dist;
			if ($dist<40000) {last;}  #version 24 optim change
		    }
		}
	    }
	    if ($near <40000) {
		push (@blue_possible,$tgt_name); 
	    }
	}
    }

    ## seleccion de SUMINISTROS a CIUDADES Azules
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/^(SUC[0-9]{2}),([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):2.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    unshift (@blue_possible,$tgt_name);
	}
    }


    ## seleccion de objetivos al azar ESTARTEGICOS AZULES (SOLO CIUDADES)
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/^(CT[0-9]{2}),([^,]+),([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^:]+):1.*$/) {
	    $tgt_name=$2;
	    $cxo=$3;
	    $cyo=$4;
	    $near=500000; # gran distancia para comenzar (500 km)
	    seek FRONT,0,0;
	    while(<FRONT>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) 2/){
		    $dist= distance($cxo,$cyo,$1,$2);
		    if ($dist < $near) {
			$near=$dist;
			if ($dist<80000) {last;}  #version 24 optim change
		    }
		}
	    }
	    if ($near <80000) {
		unshift (@blue_possible,$tgt_name);
	    }
	}
    }


    #CLIMA para la proxima mision

    my $hora;
    my $minutos;
    my $clima;
    my $nubes;
    srand;
    $mission_of_day=(($rep_count+1) % $MIS_PER_VDAY); # MoD for NEXT mission
    if ($mission_of_day==0) {$mission_of_day=$MIS_PER_VDAY;}

    my $time_increase= int(720 / $MIS_PER_VDAY); # (12 hours * 60 minutes/hour) / $MIS_PER_VDAY
    $hora=6;
    $minutos=0;
    $min_diff=($rep_count % $MIS_PER_VDAY) * $time_increase;
    $min_diff+=int(rand($time_increase));  # 0 ~ ($time_increase -1) random extra time.
    $hora+= int($min_diff /60);
    $minutos+= int($min_diff % 60);

    $clima=int(rand(100))+1; #1..100 
    $clima=int(rand(98))+1; #1..98 ( no stoms and less precipitations)

    $nubes=500+(int(rand(10))+1)*100; # 500 .. 1500

    open (CLIMA,">clima.txt");
    print CLIMA $hora."\n";
    print CLIMA $minutos."\n";
    print CLIMA $clima."\n";
    print CLIMA $nubes."\n";
    close(CLIMA);

    open (CLIMACTL,">>clima_control.txt");
    print CLIMACTL "Al reportar $MIS_TO_REP ( rep $rep_nbr ) hora: $hora min: $minutos nubes: $nubes clima: $clima = ";

    my $tipo_clima;
    if ($clima<=20){ # clima 1..20 -> 20% Clear
	$tipo_clima="Clear";
	$nubes=" -- "; # para  la pagina del generador. (ya esta guardado en disco).
    }
    if ($clima>20 && $clima<=90){ # clima 21..90 -> 70% Good
	$tipo_clima="Good";
    }
    if ($clima>90 && $clima<=95){ # clima 91..95 -> 5% Blind
	$tipo_clima="Low Visibility";
    }
    if ($clima>95 && $clima<=99){ # clima 96..99 -> 4% Rain/Snow
	$tipo_clima="Precipitations";
    }
    if ($clima>99 && $clima<=100){ # clima only 100 -> 1% Strom
	$tipo_clima="Storm";
    }
    my $localt=`date`;
    print CLIMACTL "$tipo_clima : $localt";
    close(CLIMACTL);

    $MAP_FILE="$PATH_TO_WEBROOT/mapa.html";
    my $Options_R="Options_R.txt";
    my $Options_B="Options_B.txt";
    my $Status="Status.txt";

#    if ($WINDOWS) {
#	eval `copy $CGI_BIN_PATH\\$Options_R $DATA_BKUP\\$Options_R$ext_rep_nbr`; # win
#	eval `copy $CGI_BIN_PATH\\$Options_B $DATA_BKUP\\$Options_B$ext_rep_nbr`; # win
#    }
#    else {
#	eval `cp $CGI_BIN_PATH/$Options_R $DATA_BKUP/$Options_R$ext_rep_nbr`;
#	eval `cp $CGI_BIN_PATH/$Options_B $DATA_BKUP/$Options_B$ext_rep_nbr`;
#    }

    open (MAPA,">$MAP_FILE")|| print "<font color=\"ff0000\"> ERROR: NO SE PUEDE ACTUALIZAR LA PAGINA MAPA</font>";
    open (OPR,">$Options_R")|| print "<font color=\"ff0000\"> ERROR: NO SE PUEDE ACTUALIZAR LA PAGINA SRO</font>";
    open (OPB,">$Options_B")|| print "<font color=\"ff0000\"> ERROR: NO SE PUEDE ACTUALIZAR LA PAGINA SBO</font>";
    open (STA,">$Status")|| print "<font color=\"ff0000\"> ERROR: NO SE PUEDE ACTUALIZAR LA PAGINA SRS</font>";

    print MAPA  "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">";

    print MAPA  "<html>\n<head>\n    <META HTTP-EQUIV=\"PRAGMA\" CONTENT=\"no-cache\">\n";

    print MAPA  "    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n";

    print MAPA  "    <title>Front Map</title>\n";

    print MAPA "  </head>\n<body background=\"/images/fondo_mapa.jpg\" bgcolor=\"#ccffff\">\n<center>\n";

    print MAPA  "<a href=\"/\"><img alt=\"Return\" border=0 src=\"/images/tanks.gif\"></a><br><br>\n\n";

    print MAPA  "<font size=\"+1\">Next Mission of Day (MoD): <b> $mission_of_day / $MIS_PER_VDAY</b><br>\n";
    print STA   "<font size=\"+1\">Next Mission of Day (MoD): <b> $mission_of_day / $MIS_PER_VDAY</b><br>\n";

    print MAPA  "$hora h $minutos m - Weather: $tipo_clima  - Clouds at $nubes meters. </font><br><br>\n\n";
    print STA   "$hora h $minutos m - Weather: $tipo_clima  - Clouds at $nubes meters. </font><br><br>\n\n";

    my $k;
    for ($k=0; $k<scalar(@red_possible); $k++){
	print OPR "<option value=\"$red_possible[$k]\">$red_possible[$k]</option>\n";
    }
    for ($k=0; $k<scalar(@blue_possible); $k++){
	print OPB "<option value=\"$blue_possible[$k]\">$blue_possible[$k]</option>\n";
    }

    print MAPA  "<table border=1 ><tr><td valign=\"top\">\n";
    print STA   "<table border=1 ><tr><td valign=\"top\">\n";

    ## informe de da�os aerodormos
    print MAPA  "<b>Damaged  VVS Airfields: </b><br>\n";
    print STA   "<b>Damaged  VVS Airfields: </b><br>\n";
    print MAPA  "<table>\n<col width=\"150\"> <col width=\"50\">\n<tr><td>Airfield</td><td>Damage</td></tr>\n";
    print STA   "<table>\n<col width=\"150\"> <col width=\"50\">\n<tr><td>Airfield</td><td>Damage</td></tr>\n";

    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) { 
	if ($_ =~ m/^AF[0-9]+,([^,]+),.*,([^,]+):1/){
	    my $afname=$1;
	    my $afdam=$2;
	    if ($afdam !~ m/\./) {$afdam.=".00";}
	    if ($afdam !~ m/\.[0-9][0-9]/) {$afdam.="0";}
	    if ($afdam > 20) {
		if ($afdam>=80) {
		    if ($afdam<100) {$afdam="&nbsp;".$afdam;}
		    print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"red\"><b>$afdam%</b></font></td></tr>\n";
		    print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"red\"><b>$afdam%</b></font></td></tr>\n";
		}
		else {
		    $afdam="&nbsp;".$afdam;
		    print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"blue\"><b>$afdam%</b></font></td></tr>\n";
		    print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"blue\"><b>$afdam%</b></font></td></tr>\n";
		}
	    }
	    else {
		$afdam="&nbsp;".$afdam;
		print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"green\"><b>$afdam%</b></font></td></tr>\n";
		print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"green\"><b>$afdam%</b></font></td></tr>\n";
	    }
	}
    }
    print MAPA  "</table><br><br>\n";
    print STA   "</table><br><br>\n";
    print MAPA  "</td><td valign=\"top\">\n";
    print STA   "</td><td valign=\"top\">\n";
    print MAPA  "<b>Damaged LW Airfields: </b><br>\n";
    print STA   "<b>Damaged LW Airfields: </b><br>\n";
    print MAPA  "<table>\n<col width=\"150\"> <col width=\"50\">\n<tr><td>Airfield</td><td>Damage</td></tr>\n";
    print STA   "<table>\n<col width=\"150\"> <col width=\"50\">\n<tr><td>Airfield</td><td>Damage</td></tr>\n";
    
    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) {
	if ($_ =~ m/^AF[0-9]+,([^,]+),.*,([^,]+):2/){
	    my $afname=$1;
	    my $afdam=$2;
	    if ($afdam !~ m/\./) {$afdam.=".00";}
	    if ($afdam !~ m/\.[0-9][0-9]/) {$afdam.="0";}
	    if ($afdam > 20) {
		if ($afdam>=80) {
		    if ($afdam<100) {$afdam="&nbsp;".$afdam;}
		    print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"red\"><b>$afdam%</b></font></td></tr>\n";
		    print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"red\"><b>$afdam%</b></font></td></tr>\n";
		}
		else {
		    $afdam="&nbsp;".$afdam;
		    print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"blue\"><b>$afdam%</b></font></td></tr>\n";
		    print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"blue\"><b>$afdam%</b></font></td></tr>\n";
		}
	    }
	    else {
		$afdam="&nbsp;".$afdam;
		print MAPA "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"green\"><b>$afdam%</b></font></td></tr>\n";
		print STA  "<tr><td> $afname </td><td align=\"right\"> &nbsp;&nbsp;&nbsp;<font color=\"green\"><b>$afdam%</b></font></td></tr>\n";
	    }
	}
    }
    print MAPA  "</table><br><br></td></tr></table>\n";
    print STA   "</table><br><br></td></tr></table>\n";

    ## informe de da�os Ciudades
    print MAPA  "<table border=1 ><tr><td valign=\"top\">\n";
    print STA   "<table border=1 ><tr><td valign=\"top\">\n";

    print MAPA  "<b>State of cities under Soviet control:</b><br>\n";
    print STA   "<b>State of cities under Soviet control:</b><br>\n";

    print MAPA  "<table><tr><td>City</td><td>Damage</td><td>Suply radius</td></tr>";
    print STA   "<table><tr><td>City</td><td>Damage</td><td>Suply radius</td></tr>";

    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) {
	if ($_ =~ m/^CT[0-9]+,([^,]+),.*,([^,]+),([^,]+):1/){
	    print MAPA "<tr><td> $1 </td><td> $2% </td><td> $3 Km.</td></tr>\n";
	    print STA "<tr><td> $1 </td><td> $2% </td><td> $3 Km.</td></tr>\n";
	}
    }
    print MAPA  "</table><br><br>\n";
    print STA   "</table><br><br>\n";

    print MAPA "<br><br>\n";
    print STA   "<br><br>\n";

    print MAPA  "</td><td valign=\"top\">\n";
    print STA   "</td><td valign=\"top\">\n";

    print MAPA  "<b>State of cities under German control:</b><br>\n";
    print STA   "<b>State of cities under German control:</b><br>\n";

    print MAPA  "<table><tr><td>City</td><td>Damage</td><td>Suply radius</td></tr>";
    print STA   "<table><tr><td>City</td><td>Damage</td><td>Suply radius</td></tr>";

    seek GEO_OBJ, 0, 0;
    while(<GEO_OBJ>) {
	if ($_ =~ m/^CT[0-9]+,([^,]+),.*,([^,]+),([^,]+):2/){
	    print  MAPA  "<tr><td> $1 </td><td> $2% </td><td> $3 Km.</td></tr>\n";
	    print  STA   "<tr><td> $1 </td><td> $2% </td><td> $3 Km.</td></tr>\n";
	}
    }
    print MAPA  "</table><br><br></td></tr></table>\n";
    print STA   "</table><br><br></td></tr></table>\n";

    print MAPA  "<p><strong>Front Map:</strong><br>";
    print STA   "<p><strong>Front Map:</strong><br>";

    open (IMAP,"<$IMAP_DATA");
    while(<IMAP>){
	print MAPA;
    }
    close(IMAP);
#    print MAPA "<br><br><IMG SRC=\"/images/suply.jpg\" WIDTH=900 HEIGHT=780 BORDER=0 alt=\"Suply Radius\">\n";
    print MAPA "</center>\n</body>\n</html>\n";

    close (MAPA);
    close (STA);
    close (OPR);
    close (OPB);
}


sub draw_1pix ($$$$$) {
    my ($cx,$cy,$r,$g,$b)=@_;
    if ($cy<$ALTO && $cy>=0 && $cx<$ANCHO && $cx>=0){
	$cx*=3;
	$front_img[$cy][$cx]=$b;
	$front_img[$cy][$cx+1]=$g;
	$front_img[$cy][$cx+2]=$r;
    }
}

sub draw_octants ($$$$$$$) {
    my ($Xcenter,$Ycenter,$x,$y,$r,$g,$b)=@_;
    draw_1pix(($Xcenter+$x),($Ycenter+$y),$r,$g,$b);
    draw_1pix(($Xcenter-$x),($Ycenter+$y),$r,$g,$b);
    draw_1pix(($Xcenter+$x),($Ycenter-$y),$r,$g,$b);
    draw_1pix(($Xcenter-$x),($Ycenter-$y),$r,$g,$b);
    draw_1pix(($Xcenter+$y),($Ycenter+$x),$r,$g,$b);
    draw_1pix(($Xcenter-$y),($Ycenter+$x),$r,$g,$b);
    draw_1pix(($Xcenter+$y),($Ycenter-$x),$r,$g,$b);
    draw_1pix(($Xcenter-$y),($Ycenter-$x),$r,$g,$b);
}

sub draw_circle ($$$$) {
    my ($cx,$cy,$rad,$army)=@_;
    my $x=0;
    my $y=$rad;
    my $p=1-$rad;
    my ($b,$g,$r)= (0,0,0);
    if ($army==1) {$r=255; $g=0; $b=0;}
    if ($army==2) {$r=0; $g=0; $b=255;}
    draw_octants($cx,$cy,$x,$y,$r,$g,$b);
    while ($x<$y){
	$x++;
	if ($p<0){ 
	    $p+=2*$x+1;
	}
	else {
	    $y--;
	    $p+=2*($x-$y)+1;
	}
	draw_octants($cx,$cy,$x,$y,$r,$g,$b);
    }
}


sub make_image(){

    my $HEAD=54;  #BMP header  size
    my $METERS_PER_PIX=int(10000/$H_BLOCK_PIX); # using Horzintal scale. shuld be very simmilar to Vertical scale
    my @sector_army=();
    my @sector_ttl=();
    my @city=();
    my $ciudades;

    if (!open (IMG_IN,"<$FRONT_IMAGE")) {
	print " $big_red ERROR Can't open File $FRONT_IMAGE: $! on sub make_image\n";
	print "Please NOTIFY this error.\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $FRONT_IMAGE: $! on make_image \n\n";
	exit(0);
    }
    open (IMG_OUT,">front.bmp");
    
    binmode IMG_IN;
    binmode IMG_OUT;
    


    print "<font color=\"red\">wait </font>";
    ## 54 bytes de header.
    ##-----
    for (my $i=0; $i<$HEAD; $i++) {
	my $char=getc IMG_IN;
	print IMG_OUT $char;
    }
    
    my $B_PAD=($ANCHO*3)%4;
    if ($B_PAD) {$B_PAD=4-$B_PAD;}
    
    for (my $i=0; $i<$ALTO; $i++) {
	read(IMG_IN, my $read,($ANCHO*3+$B_PAD));
	push (@front_img,[(unpack "C*",$read)]);
    }
    close (IMG_IN);
    print "<font color=\"red\">wait </font>";
    
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/CT[0-9]{2},[^,]+,([^,]+),([^,]+),[^,]+,[^,]+,[^,]+,[^,]+,([^,]+):([12]).*$/) { 
	    push (@city,[int($1/$METERS_PER_PIX),int($2/$METERS_PER_PIX),int(1000*$3/$METERS_PER_PIX),$4]);
	}
    }
    $ciudades=int(scalar(@city));
    
    for (my $i=0; $i<$ciudades; $i++){
	draw_circle($city[$i][0], $city[$i][1], $city[$i][2], $city[$i][3]);
#    draw_circle($city[$i][0], $city[$i][1], $city[$i][2]-1, $city[$i][3]);
    }
    
    for (my $n=0; $n<$NUMEROS; $n++) { ## para cada coordenada NUMERO
	for (my $l=0; $l<$LETRAS; $l++ ) { ## para cada letra 
	    $sector_army[$n][$l]=3;
	    $sector_ttl[$n][$l]=0;
	}
    }
    
    seek FRONT,0,0;
    while(<FRONT>) {
	if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([0-3])/){
	    my $n=int($2/10000);
	    my $l=int($1/10000);
	    $sector_army[$n][$l]=$3;
	}
    }
    
    seek GEO_OBJ,0,0;
    while(<GEO_OBJ>) {
	if ($_ =~  m/SEC.{4},[^,]+,([^,]+),([^,]+),([^,]+),[^:]+:[12]/){
	    my $n=int($2/10000);
	    my $l=int($1/10000);
	    my $ttl=$3;
	    if ($ttl==1) { $ttl=2;} # para que se imprima por lo menos un pixel
	    $sector_ttl[$n][$l]=int($ttl/2);
	}
    }
    
    for (my $n=0; $n<$NUMEROS; $n++) { ## para cada coordenada NUMERO
	my $cy_blo=10000*$n+5000;
	for (my $l=0; $l<$LETRAS; $l++ ) { ## para cada letra 
	    if($sector_army[$n][$l]!=3) {next;}
	    my $cx_blo=10000*$l+5000;
	    my $near=100000;
	    my $army=0;
	    my $dist=0;
	    seek FRONT,0,0;
	    while(<FRONT>) {
		if ($_ =~ m/FrontMarker[0-9]?[0-9]?[0-9] ([^ ]+) ([^ ]+) ([0-3])/){
		    $dist= distance($cx_blo,$cy_blo,$1,$2);
		    if ($dist < $near) {
			$near=$dist;
			$army=$3;
		    }
		}
	    }
	    $sector_army[$n][$l]=$army;
	}
    }
    
    for (my $n=($NUMEROS-1); $n>=0;  $n--) { ## para cada coordenada NUMERO
	if (! ($n%3)){print "<font color=\"red\">wait </font>";}
	for (my $l=0; $l<$LETRAS; $l++ ) { ## para cada letra 
	    
	    #sector square:
	    my $ttl=$sector_ttl[$n][$l];
	    my $army=$sector_army[$n][$l];
	    my $v_limit=$ALTO-($n*$V_BLOCK_PIX);
	    my $h_limit=$ANCHO-($l*$H_BLOCK_PIX);
	    
	    my $pix_y=$n*$V_BLOCK_PIX;
	    my $pix_x;
	    my ($rb,$rg,$rr)= (0,0,0);
	    
	    for (my $cy=0; $cy<$V_BLOCK_PIX && $cy<$v_limit; $cy++) {
		$pix_x=$l*$H_BLOCK_PIX*3;
		for (my $cx=0; $cx<$H_BLOCK_PIX && $cx<$h_limit; $cx++) {
		    if ( ($cy==3 || $cy==4) && $cx>5 && $ttl>($cx-5)) {
			$front_img[$pix_y][$pix_x]=0;
			$front_img[$pix_y][$pix_x+1]=int(($cx-5)<<4);
			$front_img[$pix_y][$pix_x+2]=int(250-(($cx-5)<<4));
		    }
		    else {
			$rg=$front_img[$pix_y][$pix_x+1];
			if ( $rg>210) {
			    $rr=$front_img[$pix_y][$pix_x+2];
			    $rb=$front_img[$pix_y][$pix_x];
			    if ( $rr>210 && $rb>150 ) {
				if ($army==1){
				    $front_img[$pix_y][$pix_x]-=40;
				    $front_img[$pix_y][$pix_x+1]-=40;
				    if ($rr <240){
					$front_img[$pix_y][$pix_x+2]+=15;
				    }
				}
				else {
				    $front_img[$pix_y][$pix_x+1]-=40;
				    $front_img[$pix_y][$pix_x+2]-=40;
				    if ($rb <240){
					$front_img[$pix_y][$pix_x]+=15;
				    }
				}
			    }
			}
		    }
		    $pix_x+=3;
		}
		$pix_y++;
	    }
	}
    }
    
    
    for (my $i=0; $i<$ALTO; $i++) {
	print IMG_OUT pack "C*",@{$front_img[$i]};
    }
    
    print "<br>\n";
    close (IMG_OUT);
}


##---------------------------------------------------------------------
##  MAIN
##---------------------------------------------------------------------

$|++;; # stdout HOT

open (PAR_LOG,">>Par_log.txt");
autoflush PAR_LOG 1; # hot output
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." START PAR_VERSION: $PAR_VERSION\n";


if (!$unix_cgi){

    my $numero=0;
    if (scalar(@ARGV<2)) { 
	die "$0 : " .scalar(localtime(time)) ." \nERROR: No arguments passed \n";
    }
    $numero=$ARGV[0];
    $numero =~ s/[^0-9]//g;
    $IN_FILE="$CGI_TEMP_UPLOAD_DIR/badc_".$numero.".log";
    $MIS_TO_REP="badc_".$numero;
    #expect _00000
    $ext_rep_nbr=$ARGV[1];

}
else {

    open(STDERR, ">&PAR_LOG") or die;

    print &PrintHeader;
    print <<TOP;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
      <META HTTP-EQUIV="PRAGMA" CONTENT="no-cache">
      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
      <link rel="stylesheet" type="text/css" href="/badc.css">
      <title>Parser output</title>
</head>
<body>



<div id="hoja">

  <a href="/index.html"><img border="0" src="/images/logo.gif"  alt="regresar" style="margin-left: 40px; margin-top: 0px" ></a>
  <br><br><br><br>

<div id="central">

TOP
    ;
   
    print "Reciving file...<font color=\"red\">Wait </font><br>\n";

    $cgi_lib::writefiles = "";   
    $cgi_lib::maxdata = 0;
    $cgi_lib::writefiles = $CGI_TEMP_UPLOAD_DIR;   # Spool the files to the /tmp directory
    $cgi_lib::maxdata = $MAX_UPLOAD_SIZE;              # Limit upload size to avoid using too much memory

    my (%in,  # The form data
	%cgi_cfn,   # The uploaded file(s) client-provided name(s)
	%cgi_ct,    # The uploaded file(s) content-type(s).  These are
	            #   set by the user's browser and may be unreliable
	%cgi_sfn,   # The uploaded file(s) name(s) on the server (this machine)
	$ret,       # Return value of the ReadParse call.       
	$buf        # Buffer for data read from disk.
	);
    
    if ($ENV{'CONTENT_LENGTH'} > $MAX_UPLOAD_SIZE) { #  
	print "$big_red ERROR: Uploaded file is too big.<br> Max allowed size is $MAX_UPLOAD_SIZE bytes.\n";
#	unlink $parser_lock; # lock cration moved down
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Uploaded file is too big.\n\n";
	exit(0);
    }
    $ret = &ReadParse(\%in,\%cgi_cfn,\%cgi_ct,\%cgi_sfn);

    if ($ENV{'CONTENT_LENGTH'} > ($MAX_UPLOAD_SIZE * 0.75)) { #  
	print "$big_red Warn: $close_big_red Your <b>$cgi_cfn{'upfile'}</b> file is $ENV{'CONTENT_LENGTH'} bytes long.\n";
	print "<br>This is close to max size allowed of $MAX_UPLOAD_SIZE bytes. Remember to delete it (or rename it) after this report, so you will avoid upload size error in future reports.<br><br>Continue reporting: ... <br><br>"
	}
 
    $IN_FILE="";
    $MIS_TO_REP="";

    $IN_FILE=$in{'upfile'};       # unix
    $MIS_TO_REP=$in{'num'};       # unix

    $host_name=$in{'host'};
    $host_pwd=$in{'pwd'};
    $host_name =~ s/ //g;
    $host_pwd  =~ s/ //g;

    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ReadParse data OK: $host_name $MIS_TO_REP \n";

#    print "Checking for null names or null passwords: ";
    if ($host_name eq "") {
	print "$big_red Error: HostName empty <br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
#	unlink $parser_lock; # lock cration moved down
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: HostName is empty\n\n";
	exit(0);
    }
    if ($host_pwd eq "") {
	print "$big_red Error: Password is NULL<br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
#	unlink $parser_lock; # lock cration moved down
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Password is NULL\n\n";
	exit(0);
    }
#    print "<font color=\"green\">OK</font><br>\n";

#    print "Checking for mission parameter: ";
    $MIS_TO_REP =~ s/\.mis//; # delete .mis
    $MIS_TO_REP =~ s/ //; # delete spaces

    if ($MIS_TO_REP =~ m/[^0-9]*([0-9]+)/){  # capture numbers after optional initial text
	$MIS_TO_REP="badc_".$1;
    }
    if ($MIS_TO_REP !~ m/^badc_[0-9]{5}$/i){
	print "$big_red Error: Incorrect mission number parameter<br>\n";
	print "Mission  must be like: badc_ and 5 numbers.<br>\n";
	print "For example, to report mission 30125 enter: badc_30125<br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
#	unlink $parser_lock; # lock cration moved down
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Incorrect mission number parameter\n\n";
	exit(0);
    }
#    print "<font color=\"green\">OK</font><br>\n";


#    print "Checking  uploaded file: ";
    if ($cgi_cfn{'upfile'} eq "") {
	print "$big_red Error: No file uploaded.<br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
#	unlink $parser_lock; # lock cration moved down
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: No file uploaded\n\n";
	exit(0);
    }
#    print "<font color=\"green\">OK</font><br>\n";
#    print "File recived:  $cgi_cfn{'upfile'}<br><br>\n";

    my $old_pid=$$;
    eval {fork and exit;};
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." Fork OK, parent pid was $old_pid \n";

    print "Checking for file lock: ";

    if ( -e "$parser_lock" || -e "$gen_lock" || -e "$parser_stop"){
	print "<br>$big_red ERROR: Server Busy.<br>Please try to report in some minutes.<br>\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: lock file found\n\n";
	exit(0);
    }
    else {
	open (LK,">$parser_lock"); #generamos uno
	print LK "$$\n"; #imprimimos PID en primera linea.
	close (LK);
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." Lock created\n";
    }
    
    if (! open (LK,"<$parser_lock")) {
	print "<br> $big_red ERROR: Lock reopen fail.<br>\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: lock reopen fail.\n\n";
	exit(0);
    }
    else {
	$_ =readline(LK);
	close(LK);
	if ($_ != $$) {
	    print "<br> $big_red ERROR: Currently reporting other mission. <br> Try again in couple of minutes.<br>\n";
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: not my lock $$ $_ \n\n";
	    exit(0);
	}
    }
    print "<font color=\"green\">OK</font><br>\n";
}
 
$dbh = DBI->connect("DBI:mysql:database=$database;host=localhost","$db_user", "$db_upwd");
if (! $dbh) { 
    if ($unix_cgi){
	print "$big_red Error: Can't connect to DB<br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
    }
    else {
	print "Can't connect to DB\n";
    }
    die "$0: Can't connect to DB\n";
}


if ($unix_cgi){
    #verificar el pwd
    print "Checking $host_name password: ";
    $sth = $dbh->prepare("SELECT password,in_sqd_name,sqd_accepted  FROM $pilot_file_tbl WHERE hlname=?");
    $sth->execute($host_name);
    @row = $sth->fetchrow_array;
    $sth->finish;
    if ($row[0] ne $host_pwd) {
	print "$big_red Error: Password incorrect.<br>\n";
	print "<br><br></div><br></div>\n";
	print &HtmlBot;
	unlink $parser_lock;
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Bad password\n\n";
	exit(0);
    }
    print "<font color=\"green\">OK</font><br>\n";

}


$MIS_TO_REP=~ s/\.//g; 
$MIS_TO_REP=~ s/\'//g; 
$MIS_TO_REP=~ s/\`//g; 

$LOG_FILE="$PATH_TO_WEBROOT/rep/$MIS_TO_REP.log";
$ZIP_FILE="$PATH_TO_WEBROOT/rep/$MIS_TO_REP.zip";
$MIS_FILE="$PATH_TO_WEBROOT/gen/$MIS_TO_REP.mis";
$DET_FILE="$PATH_TO_WEBROOT/gen/det_$MIS_TO_REP.txt";

print "Checking  for previous reports: ";
if (open (ZIP,"<$ZIP_FILE")){ # si se puede abrir es porque ya existe el reporte
    if ($unix_cgi) {
	close(ZIP);
	print "$big_red ERROR: Mission $MIS_TO_REP already reported\n";
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Mision reportada con anterioridad\n\n";
	unlink $parser_lock; 
	exit(0);
    }
}
print "<font color=\"green\">OK</font><br>\n";

#print "Checking  for local mission: ";
if (! open (MIS, "<$MIS_FILE")) {
    print "$big_red ERROR: Cant find server copy of  $MIS_TO_REP.mis <br>";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Cant find server copy of  $MIS_TO_REP.mis \n\n";
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

#print "Checking  for control data: ";
if (! open (DET, "+<$DET_FILE")){
    print "$big_red ERROR: Cant open control file from mission $MIS_TO_REP <br>";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Cant open control file from mission $MIS_TO_REP\n\n";
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

$Download="";
seek DET, 0, 0;
while(<DET>) {
    if ($_ =~ m/Download=(.*)$/) {
	$Download=$1;
	last;
    }
}

print "Checking  host matching: ";
if ($unix_cgi && ($host_name ne $Download) ) {
    if ($host_name ne $super_user) {
	print "$big_red Error: You ($host_name) was not the host. The $MIS_TO_REP host was $Download .\n";
	unlink $parser_lock;
	print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: $host_name no fue el host de  $MIS_TO_REP\n\n";
	exit(0);
    }
}
print "<font color=\"green\">OK</font><br>\n";

#print "Checking  geographic data file: ";
if (!open (GEO_OBJ, "<$GEOGRAFIC_COORDINATES")) {
    print "$big_red ERROR: Can't open File GEOGRAFIC_COORDINATES on main proc <br>\n";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open $GEOGRAFIC_COORDINATES $! on main proc\n\n";
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

#print "Checking frontline data file: ";
if (!open (FRONT, "<$FRONT_LINE")){
    print "$big_red ERROR: Can't open File FRONT_LINE on main proc <br> \n";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $FRONT_LINE: $! on main proc\n\n";
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

seek GEO_OBJ, 0, 0;
while(<GEO_OBJ>) {
    if ($_ =~ m/^MAP_RIGHT *= *([0-9]+)/) {
	$MAP_RIGHT=$1;
    }
    if ($_ =~ m/^MAP_TOP *= *([0-9]+)/) {
	$MAP_TOP=$1;
    }
    if ( defined $MAP_RIGHT && defined $MAP_TOP ) { last;} 
}
#print "Checking map size: ";
if ( (!defined $MAP_RIGHT) || (!defined $MAP_TOP) ) {  ## revisar si anda bien esto
    print "$big_red ERROR: missing MAP_RIGHT anr/or MAP_TOP values\n";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: missing MAP_RIGHT and/or MAP_TOP values .\n\n";
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

#print "Reading uploaded file: ";
if (!open (IN, "<$IN_FILE")) { 
    print "$big_red ERROR: Can't open Uploated file\n"; # este sera el archivo subido
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open $IN_FILE: $! (uploaded file)\n\n"; 
    exit(0);
}
#print "<font color=\"green\">OK</font><br>\n";

#verificamos que la mision este presente en el log
my $ultima=0;
seek IN,0,0;
while(<IN>) {
    if ($_ =~ m/Mission: .*$MIS_TO_REP/){
	$ultima=tell IN;                 ##leemos pos
    }
}
print "Checking if data belongs to $MIS_TO_REP : ";
if ($ultima==0) { # no se encontro reporte 
    print  "$big_red ERROR: Mission $MIS_TO_REP not found in the uploaded file.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Mission $MIS_TO_REP not found in the uploaded file.\n\n";
    exit(0);
}
print "<font color=\"green\">OK</font><br>\n";


if ($unix_cgi){
print "Checking mission age: ";
    $sth = $dbh->prepare("SELECT epoca from $mis_prog where misnum =?");
    $sth->execute($MIS_TO_REP);
    @row = $sth->fetchrow_array;
    $sth->finish;
    my $curr_time=time;
    my $age =$curr_time-$row[0];
    if ($row[0]<1090000000 || $age > (3*60*60)){ # if epoch is tto low or mission older then 3 hours
	$age=int($age/36)/100;
	if ($host_name ne $super_user) {
	    print "$big_red Error: $MIS_TO_REP : Mission Age: $age > 3 hours.<br>\n";
	    print "<br><br></div><br></div>\n";
	    print &HtmlBot;
	    unlink $parser_lock;
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: $MIS_TO_REP : Mission Age: $age > 3 hours.\n\n";
	    exit(0);
	}
	else { # allow super user to report old mission, printing warning
	    print "$big_red Warning: $MIS_TO_REP : Mission Age: $age > 3 hours. $close_big_red <br>\n";
	}
    }
    $age=int($age/36)/100;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." Mission Age = $age hours\n";
    print "<font color=\"green\">OK</font><br>\n";
}


# COMENZAMOS CON EL REPORTE:
if ($unix_cgi){
#    print "<h2>Report Start!</h2> <br><br>\n";
    print "Please <font color=\"red\">wait </font>\n";
#    print "<b>Do <font color=\"red\">not</font> hit reload or stop button on your browser. Tnx.</b><br><br>\n";
#    print "<pre>\n";
}
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." Comenzamos con el reporte.\n";
#creamos badc_00000.log, donde ponemos solo la mision que nos interesa, evitando restarts.
open (LOG, ">$LOG_FILE");
$ultima=0;
seek IN,0,0;
while(<IN>) {
    if ($_ =~ m/Mission: .*$MIS_TO_REP/){
	print LOG; 
	$ultima=tell IN;                 ##leemos pos
    }
}

my $ended=0;
seek IN,$ultima,0;
while(<IN>) {
    if ($_ !~ m/Mission END/ && !$ended){ # mientras no encontremos el final de mission
	if ($_ =~ m/^[0-9]{2}:[0-9]{2}:[0-9]{2}/){ # solo las lines que comenzan con hh:mm:ss
	    print LOG; 
	}
    }
    else { # aqui incluiremos las estadisticas de pilotos
	if ($ended==0){
	    print LOG; # imprimimos lineas Mission END
	    $ended=1;
	}
	if ($_ !~ m/Mission: /) { # si no encontramos el comienzo de OTRA mision imprimir lo relacionado con stats
	    if ($_ =~ m/^(-----|Name:|Score|Enemy|Friend|Fire|Hit)/){
		print LOG
	    }
	}
	else {last;} # encontramos nueva mision, por lo que terminamos.

    }
}
close(LOG); # cerramos 
if (!open (LOG,"<$LOG_FILE")){  # reabrir
    print "$big_red ERROR: Can't open File $MIS_TO_REP.log  (log reopen) on main proc\n";
    print "Please NOTIFY this error.\n";
    unlink $parser_lock;
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." ERROR: Can't open File $MIS_TO_REP.log FILE: $! (log reopen)\n\n";
    exit(0);
}


open (WARN,">>$PATH_TO_WEBROOT/warn.txt");
$warnings=0;

$stime_str=""; # start time string
$etime_str=""; # end time string
duracion_mision();

my $seg=get_segundos($etime_str)-get_segundos($stime_str);
if ($seg<($MIN_TIME_MIN*60)) {
    my $rep_min=int($seg/60);
    my $rep_seg=$seg-(int($seg/60)*60);
    if ($host_name ne $super_user) {
	print  "$big_red  Mission time $rep_min:$rep_seg &lt;  $MIN_TIME_MIN minutes <br>Report rejected.\n";
	print PAR_LOG "ERROR: T-LIMIT  $MIS_TO_REP : Tiempo de mision $rep_min:$rep_seg  menor al limite  $MIN_TIME_MIN - rechazado.\n\n";
	close(WARN);
	close(PAR_LOG);
	unlink $LOG_FILE; # borramos el log antes de terminar
	unlink $parser_lock;
	exit(0);
    }
    else { # allow super user to report short mission, printing warning
	print  "$big_red  Mission time $rep_min:$rep_seg &lt;  $MIN_TIME_MIN minutes $close_big_red<br>\n";
    }
}



@pilot_list=();
$hpilots=0;
build_pilot_list();
update_exp();

@PKilled_pilots=();
find_PKilled_pilots();

@task_planes_list=();
$task_groups=0;
bytask_sourvive_list();

if ($hpilots <$MIN_PILOT_NUM){  # aqui si pilotos <MIN , print warn, close all die.
    print  "$big_red ERROR: At least $MIN_PILOT_NUM pilots needed to report.</font></b><br>\n";
    print PAR_LOG "ERROR: P-LIMIT $MIS_TO_REP: Es necesario un minimo de $MIN_PILOT_NUM pilotos en total.\n\n";
    close(WARN);
    close(PAR_LOG);
    unlink $LOG_FILE; # borramos el log antes de terminar
    unlink $parser_lock;
    exit(0);
}
my $redp=0;
my $bluep=0;
for (my $i=0 ; $i<$hpilots; $i++){
    if ($pilot_list[$i][5] == 1) {$redp++;}
    if ($pilot_list[$i][5] == 2) {$bluep++;}
}
if ($redp<$MIN_PILOT_SIDE) { #: aqui si pilotos <MIN , print warn, close all die.
    print "$big_red ERROR: At least  $MIN_PILOT_SIDE pilots PER SIDE needed to report.<br>\n";
    print PAR_LOG "ERROR: RP-LIMIT $MIS_TO_REP: Es necesario un minimo de $MIN_PILOT_SIDE pilotos POR lado.\n\n";
    close(WARN);
    close(PAR_LOG);
    unlink $LOG_FILE; # borramos el log antes de terminar
    unlink $parser_lock;
    exit(0);
}
if ($bluep<$MIN_PILOT_SIDE) { # aqui si pilotos <MIN , print warn, close all die.
    print "$big_red ERROR: At least  $MIN_PILOT_SIDE pilots PER SIDE needed to report.<br>\n";
    print PAR_LOG "ERROR: BP-LIMIT $MIS_TO_REP: Es necesario un minimo de $MIN_PILOT_SIDE pilotos POR lado.\n\n";
    close(WARN);
    close(PAR_LOG);
    unlink $LOG_FILE; # borramos el log antes de terminar
    unlink $parser_lock;
    exit(0);
}


if ($unix_cgi){
    $ext_rep_nbr=get_report_nbr();  #numero de reporte extendido _00000
}
$rep_nbr=$ext_rep_nbr;
$rep_nbr =~ s/_//;


my ($MR_dia,$MR_mes,$MR_anio)=(localtime)[3,4,5];
$MR_mes+=1;
$MR_anio+=1900;
if ($MR_mes <10){ $MR_mes="0".$MR_mes;}
if ($MR_dia <10){ $MR_dia="0".$MR_dia;}
my $MR_date = $MR_anio."-".$MR_mes."-".$MR_dia;

my ($MR_sec,$MR_min,$MR_hour)=(localtime(time))[0,1,2];
if ($MR_sec <10){ $MR_sec="0".$MR_sec;}
if ($MR_min <10){ $MR_min="0".$MR_min;}
if ($MR_hour <10){ $MR_hour="0".$MR_hour;}
my $MR_time = $MR_hour.":".$MR_min.":".$MR_sec;

my $MR_epoca = time;    

$dbh->do("UPDATE $mis_prog SET reported = 1, rep_date = \"$MR_date\", rep_time = \"$MR_time\", rep_epoca = $MR_epoca, misrep = \"rep$ext_rep_nbr\" WHERE misnum=\"$MIS_TO_REP\"");
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." rep_nbr: $rep_nbr \n";

open (DATA_BK, ">$DATA_BKUP/$GEOGRAFIC_COORDINATES$ext_rep_nbr");
seek GEO_OBJ,0,0;
while(<GEO_OBJ>) {
    print DATA_BK;
}
close(DATA_BK);

open (DATA_BK, ">$DATA_BKUP/$FRONT_LINE$ext_rep_nbr");
seek FRONT,0,0;
while(<FRONT>) {
    print DATA_BK;
}
close(DATA_BK);


my $ho=int($seg/3600);
my $mi=int(($seg-($ho*3600))/60);
my $se=int($seg-($ho*3600)-($mi*60));
#if ($unix_cgi){print "Duration time of the Mission: ".$ho."h ".$mi."m ".$se."s\n\n";}


$RED_ATTK_TACTIC=0;
$BLUE_ATTK_TACTIC=0;
$RED_RECON=0;
$BLUE_RECON=0;
$RED_SUM=0;
$BLUE_SUM=0;
$RED_SUM_AI=0;
$BLUE_SUM_AI=0;
$RED_SUM_AI_LAND="";
$BLUE_SUM_AI_LAND="";
$RED_CAPTURA=0;
$BLUE_CAPTURA=0;
$red_tgt_code="";
$blue_tgt_code="";
$red_target="";
$blue_target="";
$red_tgtcx=0;
$red_tgtcy=0;
$blue_tgtcx=0;
$blue_tgtcy=0;
$red_objects=0;
$blue_objects=0;
$gen_time="";
$rep_time="";
$Download="";
$Redhost="";
$Bluehost="";
$mission_time=0;
$cloud_type="";
$clima_mision="";
$red_af1_code="NO_MATCH";
$red_af2_code="NO_MATCH";
$blue_af1_code="NO_MATCH";
$blue_af2_code="NO_MATCH";
$MAP_NAME_LOAD="Unknow";
$MAP_NAME_LOAD="Unknow";
read_mis_details();

$mission_time= int((($mission_time *60) / 60))."h ".(int(($mission_time *60) % 60)) ."m"; 


my $tb1_bgcolor="#eeeeee";
my $cel_tb2_bgc="#dddddd";

# OPEN HTML REPORT:

open (HTML_REP,">$PATH_TO_WEBROOT/rep/rep$ext_rep_nbr.html"); #generamos uno

print HTML_REP <<EB1;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
      <link rel="stylesheet" type="text/css" href="/badc.css">
      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
      <title>Report: $rep_nbr  - Mission: $MIS_TO_REP</title> 

<!-- ## REMOVED JAVASCRIPT TOOLTIP STYLE -->

</head>
<body>

<div id="dhtmltooltip"></div>

<script type="text/javascript">

/***********************************************
* Cool DHTML tooltip script- � Dynamic Drive DHTML code library (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
***********************************************/
    
var offsetxpoint=-60;
var offsetypoint=20;
var ie=document.all;
var ns6=document.getElementById && !document.all;
var enabletip=false;
if (ie||ns6)
    var tipobj=document.all? document.all["dhtmltooltip"] : document.getElementById? document.getElementById("dhtmltooltip") : "";

function ietruebody(){
    return (document.compatMode && document.compatMode!="BackCompat")? document.documentElement : document.body;
}

function ddrivetip(thetext, thecolor, thewidth) {
    if (ns6||ie){
	if (typeof thewidth!="undefined") tipobj.style.width=thewidth+"px";
	if (typeof thecolor!="undefined" && thecolor!="") tipobj.style.backgroundColor=thecolor;
	tipobj.innerHTML=thetext;
	enabletip=true;
	return false;
    }
}

function positiontip(e) {
    if (enabletip) {
	var curX=(ns6)?e.pageX : event.x+ietruebody().scrollLeft;
	var curY=(ns6)?e.pageY : event.y+ietruebody().scrollTop;
	var rightedge=ie&&!window.opera? ietruebody().clientWidth-event.clientX-offsetxpoint : window.innerWidth-e.clientX-offsetxpoint-20;
	var bottomedge=ie&&!window.opera? ietruebody().clientHeight-event.clientY-offsetypoint : window.innerHeight-e.clientY-offsetypoint-20;

	var leftedge=(offsetxpoint<0)? offsetxpoint*(-1) : -1000;
	if (rightedge<tipobj.offsetWidth)
	    tipobj.style.left=ie? ietruebody().scrollLeft+event.clientX-tipobj.offsetWidth+"px" : window.pageXOffset+e.clientX-tipobj.offsetWidth+"px";
	else if (curX<leftedge)
	    tipobj.style.left="5px";
	else
	    tipobj.style.left=curX+offsetxpoint+"px";
	
	if (bottomedge<tipobj.offsetHeight)
	    tipobj.style.top=ie? ietruebody().scrollTop+event.clientY-tipobj.offsetHeight-offsetypoint+"px" : window.pageYOffset+e.clientY-tipobj.offsetHeight-offsetypoint+"px";
	else
	    tipobj.style.top=curY+offsetypoint+"px";
	tipobj.style.visibility="visible";
    }
}

function hideddrivetip() {
    if (ns6||ie){
	enabletip=false;
	tipobj.style.visibility="hidden";
	tipobj.style.left="-1000px";
	tipobj.style.backgroundColor='';
	tipobj.style.width='';
    }
}

document.onmousemove=positiontip;

</script>

<!-- ## REMOVED JAVASCRIPT TOOLTIP CODE -->

<div id="reporte">

  <a href="/index.html"><img border="0" src="/images/logo.gif" 
     alt="regresar" style="margin-left: 40px;"></a>

<center><h3>Report Number:&nbsp;$rep_nbr&nbsp;-&nbsp;Mis:&nbsp;$MIS_TO_REP</h3></center>

<center>
<table border="1" bgcolor="$tb1_bgcolor">
<tr>

<td> <table border="0">
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Mission file </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"><a href="/rep/$MIS_TO_REP.zip">$MIS_TO_REP.zip</a></td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Event file </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"><a href="/rep/$MIS_TO_REP.log">$MIS_TO_REP.log</a></td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Event maps </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc" > 
       &nbsp;&nbsp; <a href="/rep/map_1x_$rep_nbr.html">1X</a>&nbsp;&nbsp; 
        &nbsp;&nbsp;<a href="/rep/map_2x_$rep_nbr.html">2X</a>&nbsp;&nbsp; 
        &nbsp;&nbsp;<a href="/rep/map_4x_$rep_nbr.html">4X</a>&nbsp;&nbsp;</td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Generated </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $gen_time </td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Reported </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $rep_time </td></tr>
</table> </td>

<td> <table border="0">
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Duration</td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $ho h $mi m $se s </td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Time start</td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $mission_time  </td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Weather </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $clima_mision </td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">Soviet Req </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $Redhost </td></tr>
<tr><td align="right" class="ltr80" bgcolor="$cel_tb2_bgc">German Req </td>
    <td class="ltr80" bgcolor="$cel_tb2_bgc"> $Bluehost </td></tr>
</table> </td>

</tr>
</table>
</center>

EB1
    ; # Emacs related


$red_sum_city="NO CITY";
if ($RED_SUM) {
    $red_sum_city=$red_target;
    $red_sum_city =~ s/SUM-//;
#    $red_tgt_code="NO MATCH" # para que no interfiera con el look_af_ct
}
$blue_sum_city="NO CITY";
if ($BLUE_SUM) {
    $blue_sum_city=$blue_target;
    $blue_sum_city =~ s/SUM-//;
#    $blue_tgt_code="NO MATCH" # para que no interfiera con el look_af_ct
}

$RED_CAPTURA=0;
$BLUE_CAPTURA=0;
$blue_damage=0;
$red_damage=0;
$blue_resuply=0;
$red_resuply=0;

@af_resup=();

$red_result="";  # para mis_prog_tbl
$blue_result=""; # para mis_prog_tbl
print_mis_objetive_result();

@land_in_base=(); # pilotos que aterrizan en su base (para descontar en cada rescat)
@last_land_in_base=(); # pilotos que aterrizan por ultima vez en su base
@rescatados=();  # listado de pilotos rescatados, para no contarlos como mia al evaluar pilotos perdidos
find_safe_pilots();


$massive_disco=0;
detect_massive_disco();

$red_points=0; # para mis_prog_tbl
$blue_points=0; # para mis_prog_tbl
print_pilot_actions();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." pilot_actions ok\n";


my $side_won=0; # default = empate
if ($red_points>$blue_points) {
    $side_won=1;
}
if ($red_points<$blue_points) {
    $side_won=2;
}

$dbh->do("UPDATE $mis_prog SET red_result = \"$red_result\", blue_result = \"$blue_result\", red_points = $red_points, blue_points = $blue_points, side_won = $side_won WHERE misnum=\"$MIS_TO_REP\"");


$red_planes_destroyed=0;
$blue_planes_destroyed=0;
$red_af1_lost=0;
$red_af2_lost=0;
$blue_af1_lost=0;
$blue_af2_lost=0;
$red_af1_kia=0;
$red_af2_kia=0;
$blue_af1_kia=0;
$blue_af2_kia=0;
eventos_aire();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." eventos aire ok\n";

eventos_tierra();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." eventos tierra ok\n";

###Primero Revisamos si hubo ataque a aerodromos y/o cuidades
###actualizamos los da~nos y radios de suministro.
look_af_and_ct();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." look_af_and_ct ok\n";

## luego actualizamos los resuply (si hubo)
look_resuply();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." look_resuply ok\n";

###Hahora revisamos si hubo captura de sectore y actualizamos linea de frente
@red_cap=();
@blue_cap=();
@red_ttl_recover=();
@blue_ttl_recover=();
look_sectors();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." look_sectors ok\n";

check_geo_file(); #actualizamos  GEOGRAFIC_COORDINATES si FRONT_LINE_VERSION cambio.
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." check_geo_file ok\n";

### Aqui actualizar si los sectores estan dentro del radio de suministro.
check_sec_sumin();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." check_sec_sum ok\n";

###CADA 30 misiones se avanza un dia, recuperando un poco las ciudades y los aerodromos.
check_day(); # en base a xx misiones REPORTADAS? REVISAR
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." check_day ok\n";

### creamos una nueva pagina de seleccion de objetivos
make_attack_page();
print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." make attk page ok\n";

# Disconnect from the database.
$dbh->disconnect();


my @front_img=();

#    print "Creating new front images, this will take some seconds:\n";

if ($unix_cgi) {
    make_image();
    if ($WINDOWS) {
	eval `$CJPEG_PROG $CJPEG_FLAGS front.bmp > $PATH_TO_WEBROOT\\images\\front.jpg`; # win
    }
    else {
	eval `$CJPEG_PROG $CJPEG_FLAGS front.bmp > $PATH_TO_WEBROOT/images/front.jpg`;
    }
    unlink "front.bmp";
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." make front image ok\n";
}

# isolated sectors just changed to other side, mybe are recovered back 
# because ttl/distance to city. So we search into all recovered secotors
# and takem out from lost by isolation list

foreach my $rec_sect (@red_ttl_recover) { 
    my $t = scalar(@red_cap);
    for ($i=0; $i<$t; $i++){
	$cap_sect= shift (@red_cap);
	if ($rec_sect ne $cap_sect) { 
	    push(@red_cap,$cap_sect);
	}
    }
}

foreach my $rec_sect (@blue_ttl_recover) { 
    my $t = scalar(@blue_cap);
    for ($i=0; $i<$t; $i++){
	$cap_sect= shift (@blue_cap);
	if ($rec_sect ne $cap_sect) { 
	    push(@blue_cap,$cap_sect);
	}
    }
}


if ((! scalar(@red_cap)==0) || (! scalar(@blue_cap)==0))  {
    print HTML_REP "<p><br><br>\n";
    print HTML_REP "<center><h3>Notes:</h3></center>\n\n";
}
if (! scalar(@red_cap)==0){
	print WARN  "$MIS_TO_REP Soviets lost sector(s) isolated ".join(" ",@red_cap)."\n";
	print HTML_REP  "<center> <strong>Soviets lost sector(s) isolated ".join(" ",@red_cap)."</strong>.</center><br>\n";
}
if (! scalar(@blue_cap)==0){
	print WARN  "$MIS_TO_REP German lost sector(s) isolated ".join(" ",@blue_cap)."\n";
	print HTML_REP  "<center> <strong>German lost sector(s) isolated ".join(" ",@blue_cap)."</strong>.</center><br>\n";
}
if (! scalar(@red_ttl_recover)==0){
	print WARN  "$MIS_TO_REP Soviets recover sector(s) by ttl ".join(" ",@red_ttl_recover)."\n";
}
if (! scalar(@blue_ttl_recover)==0){
	print WARN  "$MIS_TO_REP German recover sector(s) by ttl ".join(" ",@blue_ttl_recover)."\n";
}



print HTML_REP <<EB2;

<a id="reports"></a>
<br><br><br>
<center>
<table>
<col width="80"><tr><td></td></tr>



</table>
</center>
<div id="final">
<br>
<a href="/cgi-bin/write_comm.pl?repnbr=rep_$rep_nbr">Write report</a><br><br>
<a href="/index.html" title="Inicio">Return</a>
<br>
<br>
</div> <!-- Cierra final -->
</div> <!-- Cierra reporte -->
</body></html>
EB2
    ; # emacs related

## cerramos los archivos
## ---------
close(HTML_REP);
close(FRONT);
close(GEO_OBJ);    
close(MIS);
close(LOG);
close(DET);
close(WARN);


if (! $unix_cgi){
    print "Mission reported: rep".$ext_rep_nbr.".html \n";
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." MIS: $MIS_TO_REP  REP: $rep_nbr - END OK - Warns= $warnings\n\n";
}
else {
    if ($WINDOWS) { 
	eval `copy  $PATH_TO_WEBROOT\\gen\\$MIS_TO_REP.zip $PATH_TO_WEBROOT\\rep\\$MIS_TO_REP.zip`; # win
	if ($ZipCode ne "") {
	    eval `rmdir /Q /S $PATH_TO_WEBROOT\\tmp\\$ZipCode`; # win
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." $PATH_TO_WEBROOT/tmp/$ZipCode deleted ok\n";
	    eval `del /Q  $PATH_TO_WEBROOT\\gen\\$MIS_TO_REP.zip`;  # win
	    eval `del /Q  $PATH_TO_WEBROOT\\gen\\$MIS_TO_REP.mis`;  # win
	    eval `del /Q  $PATH_TO_WEBROOT\\gen\\$MIS_TO_REP.properties`;  # win
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." $MIS_TO_REP zip/mis/prop deleted ok\n";
	}
    }
    else {
	eval `cp  $PATH_TO_WEBROOT/gen/$MIS_TO_REP.zip $PATH_TO_WEBROOT/rep/$MIS_TO_REP.zip`; 
	if ($ZipCode ne "") {
	    eval `rm -fr $PATH_TO_WEBROOT/tmp/$ZipCode`;
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." $PATH_TO_WEBROOT/tmp/$ZipCode deleted ok\n";
	    eval `rm  $PATH_TO_WEBROOT/gen/$MIS_TO_REP.zip`;  
	    eval `rm  $PATH_TO_WEBROOT/gen/$MIS_TO_REP.mis`;  
	    eval `rm  $PATH_TO_WEBROOT/gen/$MIS_TO_REP.properties`;
	    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." $MIS_TO_REP zip/mis/prop deleted ok\n";
	}
    }
    unlink $parser_lock; # borramos el lock
    print PAR_LOG " Pid $$ : " .scalar(localtime(time)) ." MIS: $MIS_TO_REP  REP: $rep_nbr - END OK - Warns= $warnings\n\n";
    close(PAR_LOG);
    sleep 2;
    print "\n\n</pre>\n";
    print " Mission reported: <a href=\"/rep/rep".$ext_rep_nbr.".html\">rep".$ext_rep_nbr.".html</a><br>";
    print "<br><br></div><br></div>\n";
    print &HtmlBot;


}

# useless lines to avoid used only once messages 
$database=$database;
$db_user=$db_user;
$db_upwd=$db_upwd;
$IMAP_DATA=$IMAP_DATA;
$rescue_tbl=$rescue_tbl;
$ground_events_tbl=$ground_events_tbl;
$air_events_tbl=$air_events_tbl;
$INIT_BAN_PLANNIG=$INIT_BAN_PLANNIG;
$MIN_MIS_TO_PLAN=$MIN_MIS_TO_PLAN;
$TANK_REGEX=$TANK_REGEX;
$H_BLOCK_PIX=$H_BLOCK_PIX;
$V_BLOCK_PIX=$V_BLOCK_PIX;
$ALTO=$ALTO;
$ANCHO=$ANCHO;
$super_user=$super_user;
$AF_VDAY_RECOVER=$AF_VDAY_RECOVER;
$CT_VDAY_RECOVER=$CT_VDAY_RECOVER;
$close_big_red=$close_big_red;
$gen_lock=$gen_lock;
$parser_stop=$parser_stop;
$ALLOW_AUTO_REGISTER=$ALLOW_AUTO_REGISTER;
