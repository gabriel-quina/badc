The following is a fast overview of how to install campaign.
Here is a index of what this file contents:

+A) REQUERIMENTS

+B) INSTALL
1) Clone this repository
2) Create a database (mysql), a user for that database.   
3) Place files as described in "Notes on Folder organization"
4) Edit "config.pl" and "config.php" to match DB name, DB user and DB user password
5) Load index.html and chech several pages, initialize maps

+C) NOTES
1) Notes on Windows server
2) Notes on Folder organization and Files description.
3) Notes on Logfiles
4) Notes about lockfiles.
5) Notes about counters and datafiles.
6) Notes on Authcodes
7) Notes on mission creation.
8) Notes on images.
9) Notes on javascript

+D) CREDITS

+E) LICENSE


# A - REQUERIMENTS

What you need:

Apache : version 1.3.x or new
PHP    : version 4.x or new
MySQL  : version 4.x or new   (maybe 3.x, but not tested)
Perl   : version 5.8.x or new (maybe 5.6.x, but not tested)
cjpeg  : As part of jpeg-6b
OS	  : Unix, Linux  - NOT tested on Windows servers. See "Notes on Windows server".
Optional gnuplot: 3.7 +

Notes: 

Be sure to have set on httpd.conf one of this options: "AllowOverride All" or
"AllowOverride AuthConfig" so Apache can read .htaccess files to restrict access to
certain folders. Also, you may need to set apache to know that .pl files are CGI
scripts.  It can be done with "AddHandler cgi-script .pl" on a .htacces file.

To run Perl scripts you need this modules DBI and DBD::mysql. If you use DBD::mysqlPP
module you have to change scripts manually to mach this.



# B - INSTALL


1. Clone this repository into a temporary place

2. Create a database, a user for that database. Table definitions are in a file called
"new_tables.sql". Create the tables with a command like: 
(in example DB=badc user=lucy password=some_passwd)
There are some more table definifinion on files:
"votes_tbl.sql"
"badc_6_HL_slots.sql"

Example how to create databases from shell ($ is shell prompt)

$ mysql --user=root -pYOUR_MYSQL_ROOT_PASSWORD

mysql> create database badc;
mysql> grant all privileges on badc.* to lucy@localhost identified by 'some_passwd' with grant option;
mysql> exit

Now this commands from shell:

$ mysql badc --user=lucy -psome_passwd < new_tables.sql
$ mysql badc --user=lucy -psome_passwd < votes_tbl.sql
$ mysql badc --user=lucy -psome_passwd < badc_6_HL_slots.sql

If you do not have shell access just use some software like phpMyAdmin

**WARINIG**: any older tables from a running campaing will be droped!! This is to create
new tables only, for first time, or to reset all to 0. Pilot data, squadrons stats, all
will be lost if you run this on a running campaign.

3. Place files as described in "Notes on Folder organization". Basically just copy all
files into your webroot folder. Set correct permissions: all .pl must be with exec
attributes (chmod a+x *.pl) allmost all txt files, log files, and campaing datas need
to have write attributes. Also write attributes on temporary folders.


4. Edit "config.pl" and "config.php" to match DB name, DB user and DB user password,
folder paths, program path and other values. There is a description on each value
inside config.pl file. 

Edit other mission requeriments, like amount of total human players, amount of players
per side,  amount of missions per virtual day, dayly AF and city damage recover, damage
to AF per each pilot killed and for each plane lost, etc...

5. Load index.html and use you browser to check if all works ok. 

Note!! : Remember to set correct perl path on all .pl files

Note!! : Make sure scripts are in correct newline format (used dos2unix util if need)
If you get script error can be because incorrect newlines translations
errors are "premature end of script headers"

Register a pilot (you) with same name defined as super_user on config.pl
Load ref_map.html and run 2 scripts: make attack page, make front.

Later register another pilots, 2 squadrons, go and make some mission, then try to report.

IMPORTANT: Before you can register a squadron you have to add authcodes into
   "claves.txt" Read more about this on "Notes on Authcodes".
IMPORTANT: Be sure to set correct host name on ref1 and ref2 values, if you do not
set this ok you will get an error on planning a mission " Incorrect HTTP_REFERER"

Once you have all ready and like to start a campaign, you have to restore data files
(GEO_OBJ and FRONTLINE) because they are changed on all reports.

Customize your web site. Please do NOT use "Bellum" as campaign name. Bellum is the
first campaign runnin with this "BADC" (bourne again dinamic campaign). Set you desired
campaign name, change the rules as you like, customize languages, change sources to
introduce new fertures, build your style pages, and any customization you like.


IMPORTANT: default pilot registration sets ban_plannig=0, that is you can make
requests. If you change (default to ban) you will nedd to set plannig rights to some
pilots, so they can make request. To do that, conect to mysql and run:
mysql>update bell_pilot_file set ban_planing=0;
This will give plannig to *all* registered pilots. To give only planing to one pilot do:
mysql>update bell_pilot_file set ban_planing=0 where hlname="PILOT_NAME";


When a map is over, go to config.pl, change config to use a new map, the go to
ref_map.html and run all 3 scripts to make map, front and suply images.

In the DOCS folder you have a dump of FAQ and manual add ons from bellum forum.
understanting on how campaing works will help understand the code too.

The MAP_DATAS folder contains original data files. In case you like to restart a map,
here they are. Some of Those data files when are placed on CGI-BIN folder are changed
as campaigns run.

# C- NOTES

1)Notes on Windows server

I really dont know if it can work or not. I made only a few test using Windows XP SP2 +
IndigoPerl +MySQL. Scripts works ok. But i didnt strong tested all programs. The only
modification needed is the path to perl on the first line of ALL .pl files:

If perl is on your path this will work:
#!perl
If not, place complete path to perl:
#!C:\path_to_perl\perl

I can't say if there is a
gnuplot version for windows, and havent tested image convertions using cjpeg.exe

You can get Mysql for windows here: http://dev.mysql.com/downloads/

Perl for windows https://www.perl.org/get.html

cjpeg for windows aviable here : http://gnuwin32.sourceforge.net/packages/jpeg.htm
gnuplot for windows: http://www.gnuplot.info/

config.pl looks different for windows server because windows uses backslash as folder
limiters, so an extra backslash is need to escape. Make sure paths do NOT contains spaces.
If they do, you have to add escaped quotes. Take a look into config_windows.pl examples.

2)Notes on Folder organization and Files description.

There are some folder that are mandatory, becasue there is no option on config to
change them. It is possible to do but you have to manually change all script and php
files, or better, set them as variables and later place them on config.* files
The mandatory folders layout are:

Home

\\---public_html          Web root (html, php, css and other files)

|---gen              generated data files (control files, mis, properties)

|---images           general images dir

|---rep              html reports, reported missions zip files and eventlogs

\\---tmp              temporary place for mission download

Aditionally you can set up custom place for:
cgi-bin folder   :    to hold scripts and campaing datafiles
a temp folder    :    for mission upload and some other cgi temporary data (plot[123].pl) uses a temp folder.
data-backup folder :    to hold backup data

This is the layout i use:

Home                      

\\---public_html          Web root (html, php and other files)

|---cgi-bin          CgiExec dir (most perl and data files)

|   |---data_bkup    backups for data before reporting a mission

|   \\---tmp          temp dir for cgi plots data files and upload missions

|---gen              generated data files (control files, mis, properties)

|---images           general images dir

|---rep              html reports, reported missins zip files and eventlogs

\\---tmp              temporary place for mission download

Another layout:

Home                      

|---public_html          Web root (html, php and other files)

|   |---gen              generated data files (control files, mis, properties)

|   |---images           general images dir

|   |---rep              html reports, reported missins zip files and eventlogs

|   \\---tmp              temporary place for mission download

|

\\---cgi-bin              CgiExec dir (most perl and data files)

|---data_bkup        bakups for data before reporting a mission

\\---tmp              temp dir for cgi plots data files


GENERAL HTML/PHP FILES
index.html     Main index page
manual.html    Manual page
news.html      Archived news page
points.html		 Information on Points system
tasks.html		 Information about tasks 
under.html		 Simple "under construction page"
block.php      blocks unknow user agents

REGISTER RELATED HTML/PHP FILES
registro.html		    Main register menu
pilot_reg.html		  Pilot registration
join_sqd.php		    Pilot join a squadron
leave_squadron.php	Pilot leave squadron	
delete_pilot.php	  Pilot delete from database
sqd_reg.html		    Squadron registration
sqd_admin.php		    Squad admin, step 1
sqd_admin2.php	  	Squad admin, step 2
** NOTE: some register scripts are in perl, direct link to them. 

STATS RELATED HTML/PHP FILES
all_pilots.php		Show all pilots stats
alive_pilots.php	Shows alive pilots stats
all_sqds.php		  Shows squadrons stats
sqd_file.php		  Specific squadron roster/stats
pilot.php		      Specific pilot stats
show_akills.php		Specific pilot airkills
show_gkills.php		Specific pilot groundkills
show_rescues.php	Specific pilot rescues

MISSION RELATED HTML/PHP FILES
create.php		    Creation page, mission in progres and today missions
last_mis.php		  Last missions of today and links to previous days
mis_download.php	Download confirmation page
take_slot.php		  Used to take a host or plannig slot on create.php
rep_input.html		Page to report (upload) a missions, a simple form
mapa.html         Map page  (created by parser, after every report)
no_click.html     Information about imagemaps are only to find sector/city name

INFORMATION HTML/PHP FILES
find_pilot.php		Find a pilot file
find_sqd.php		  Find a squadron file

ADMIN HTML/PHP FILES     (for super user only, defined in config.pl)
config.php		           Configuration file for PHP
ref_map.html             Maintenance pages, to choose one of the 3 next...
ref_attack_page.html     Rebuild Target places,  map status page.
ref_front_image.html     remake Frontline imaga based on current fronline status
ref_suply_image.html     remake sulply image based on current geographic data

NOT HTML/PHP FILES
robots.txt		 Simple robots.txt file
warn.txt		   Parser warning list

PERL SCRIPTS:
accept_pilot.pl     : accept pilot
allow_images.pl     : allow display german images with historical marks
badc_gen_1.pl       : BADC generator
badc_par_1.pl       : BADC parser
config.pl           : configuration file
delete_pilot.pl     : delete a pilot
disallow_images.pl  : disallow display german images with historical marks
gen_opts_31.pl      : read user request options and write down for later use by generator
join_sqd.pl         : join squadron 
leave_slot.pl       : leave a slot from create.php page
leave_squad.pl      : leave a squadron
make_attack_page.pl : refresh the map.html, target places and status info
make_front_image.pl : refresh front image
make_suply_image.pl : refresh suply image
pilot_edit.pl       : edit pilot information
pilot_reg.pl        : register a pilot
plo1.pl             : plots virtual lives/sorties
plo2.pl             : plots airkills/sorties
plo3.pl             : plots groundkills/sorties
reject_pilot.pl     : reject a pilot aplication (not allow to join)
sqd_edit.pl         : Edit squadron infromation
sqd_reg.pl          : Register a squadron
take_slot.pl        : take a slot from create.php -> take_slot.php
test.pl		          : test instalation program
write_comm.pl       : write comment on static html reports.

3)Notes on Logfiles

There are several log files, 3 are the more important:
- Gen_log.txt is the generator logfile. 
- Par_log.txt is the parser logfile.
- Pilot_log.txt is the logfile that holds all registration, pilot deletion, and other
pilot/sqds actions.

Other logs are:
clima_control.txt:  logfile with weather setup after a reported mission
used_claves.txt: logfile of all used authcodes
warn.txt: logfile with all parser warning, visible from website.
options.txt: holds all mission requests, not sorted
used_options.txt: holds all combination of request to build a mission.


4)Notes about lockfiles.

Default locks are _gen.lock and _par.lock
If this files appears, check logfiles. check is there is a corrupt mission report (html,Mysql)
after detecting what was problem, (fix html, fix mysql, etc) remove files.
Used also to lock programs on special cases, updating data, server problem, etc. Just
manualy create those files in cgi-bin folder.


5)Notes about counters and datafiles.

mis_counter.data : holds mission number, format is underscore plus 5 digits. ex  _000001
rep_counter.data : holds report number, format is underscore plus 5 digits. ex  _000001

6)Notes on Authcodes

Authcodes are there to avoid massive squad registration. If you force to get an auth code,
the interested has to register in forum. Many times people gets tired on register in a new
forum, and they do not participate because that, so, at least the commander of squadrons
knows where is the forum, it will be registered on forum , and this helps on participation
and get involved.

Valid authcodes are just a list on a file (claves.txt). When someone uses a code, it is
printed into another file (used_claves.txt) with all used authcodes. So validation script
will look first into claves.txt for a valid code and if it is found it will look on
used_claves.txt file to check if it was used. Since the claves.txt holds many authcodes,
someone can try to gess one, recomended auth codes are words not in dictionary

If you want to disable this, you can edit script to avoid verification, or you can leave a
single valid code, but stop writing it to used_claves.txt. This way you have a unique code
(or many) that can be reused.

7)Notes on mission creation.

Mission creation starts on create.php by taking a host slot, then both sides takes request
slots, making each requests. Each request can be done, because take_slot.pl will display
maps, targets, plane and plane counters to fill. This information is readed from several
places:

-Selectable planes (human and AI) are listed on config.pl on every map change you have to
set new list.
-Selectable target places are readed from "Options_R.txt" and "Options_B.txt". This 2 files
are built by parser afer a report. Every time a mission is reported, map front line can
change, so targets can be or not avaliable. Parser make correct selections based on rules in
code.
-Status data (damage on city, airfields and other info) is readed from a file
"Status.txt", and like before, this file is created by parser. This file holds information
common for both sides.

This way each side can see a page to select planes, targets and plane numbers. once the
request is submited, data is inserted into database (host_slots_tbl) and specific flight
data and target is dumped into options.txt

Once both request are done host hits download link: Now generator will search in database
(host_slots_tbl) the names and other information. The specific targets and aircraft options
are readed from the file "options.txt", if all goes ok, both options are dumped into
"used_options.txt" mission is created using the number of mission from "mis_counter.data"
host_slots_tbl are cleared, mission is copied to a temporary folder password protected.

The very first question is why i use database to hold some information, and "options.txt"
to hold more specific data. Why not use only database?  The answer is because in first
stages, of development there was not a mission creation page like is now. We have just
options dumped into a file and the creation page was a simple html reading options from
"options.txt" file, and not listed on "used_options.txt". When i was developing new creation
system i focus on things like army side, a nice grafic interface, host rights, planning
rights and so on. But i never integrated all the request information on database, so i
just keep using old system with this 2 files. For sure, will be much better to include all
data into host_slots_tbl DB and forget about those 2 files.

8)Notes on images.  

All images i provide are made by me, or generous made by member comunity help on
development. Some images are used with permission and other images not made by me are
modifications of images made by other people i used as starting point, then changing shape,
brightness, details, aditions deletions. A couple of images are buttons, used to link to
other places, like Hyperlobby website and W3C validator. The emoticons i use on report
comments in bellum campaing are free avaliable to USE (not distribute) from web wiz forums.
please read "Notes on Emoticons".

Warning on Historical Markings:

I have to say that squadrons uses to easy identify which side they fly a medal image. A
Soviet star for Soviet Air force and a German medal with a Historical Markings for German air
forces. Also, there is a soviet flag and a german flag displayed close to every name on
stats, to easy know whisc side a pilot fly. Those images are historic. There is no
conection with racism or political reasons. However i make that german images are NOT
displayed by default. To see those images, user have to click on link "allow german
images" this will set a cookie and images will be displayed. You later can click on
"disallow german images" to valid them, or just delete cookies. Because default action is
not to display them.

9)Notes on javascript

I use javascript on several places. Most of cases simple checks. But 2 cases need mention:

On takeslot.pl the plane selector form is based on a script original by Vladimir Geshanov
called "form select 2D". My code is a strong modification of that
one, and selection is done by regular expression. I can easy remove his credits by
rewriting shared lines, but i prefer to mention his original work. Because that his name
and website is printed on every form using this scripts. Nothing to hide. If you plan to
remove his credit, please rewrite all selectPlane() function. That will be fair. 

Reports has a "Popup information box II" on prints link, so placing the mouse over you get
a list of all events points related to reach that score. Script is Taked from
http://www.dynamicdrive.com/dynamicindex5/dhtmltooltip.htm, that is free for use if you
keep original copyright notice (like i do). But it can NOT be distributed, so i have to
take out from parser. Also im not writing a replacement, so if you like to have the same
tool tip just go to dynamicdrive and het any tooltip you like, then change parser to
generate reports using the javascript of your preference.
You can find the place on parser (badc_par_1.pl) where the script was located and called:

      ## REMOVED JAVASCRIPT TOOLTIP STYLE
      ## REMOVED JAVASCRIPT TOOLTIP CODE

And how it was called: 
#Points description used with JAVASCRIPT TOOLTIP  (if use comment pev line)


# D- CREDITS



OK, Lets go in order: :)

First thanks is for Maddox Games for this exelent sim, no second to any other WW2
sim. Bellum campaign is possible because IL2-FB exelent design, making mission files easy
to build (just formated text) and mission results very detailled in text format. This 2
simple things, maybe not important for many other sim programmers, make a wrold of
difference. http://www.il2sturmovik.com 

Second I will thanks to all makers of online wars previous to bellum. I start to play
several online wars and after that,  based on what those projects offers and what they lack
bellum become an idea to offer the best of online wars plus new unique feratures. I cant
say bellum archived that, but what we have in belllum proved not to be so bad. Special
thanks for Starshow (VEF1 and VEF2 maker), and to VOW team. I realy know how much time and
efforts are need to make those projects

I have to mention Jiri Fojtasek for his great online lobby. He is creator of HyperLobby,
where our campaing runs.  http://hyperfighter.jinak.cz

Special thanks to Pirx (88.IAP_Pirx pirx@88-iap.de) for allow use his plane table. All his
work on colection historic planes usage is exelent. http://www.yogysoft.de/

Now is time to thanks III/JG52_Meyer, for so many conversations we have speaking about new
feartures for bellum. Many of the base options we have in bellum are there because he pointed
to me. With those ideas bellum started as a project and become public on SG1 squadron
forums. Here i got the suport needed on SG1_Gunkan to this project keep moving. You know,
he saw the light.

After that, Bellum was developed in spanish comunity, and here a very important work was
done by several squadrons, helping me to find bugs, to make new options, making
sugestions, flying testing and so on. This squadrons i like to say thanks are (in
alphabetic order): AA, AH, CN, E111, ECV56, ESA, FAE, FK1, HR, III/JG52, RedEye, SG1 and
StG_111. Some of them with more participation, but at end, all help to develop.

Several persons help me a lot in particular problems and work (web site, templates, and
other things): AH_Jacketon, HR_Ootoito, HR_Barripower, StG111_Darth_Rye, FK1_Sturmbomber,
FAE_Almogavar, SG1_Cantos, III/JG52_Orka, FAE_Coyote. Later, when bellum was on final beta
i got help from not spanish player: RR_OldMan, RC_Shtirlitz, ET=Mitya, LLv26_Mikko,
LeOs.K_Anak, just to mention by memory. I really apreciate all help for this guys and
forgive me if i missed some names, im sure list is incomplete because i got help from many
other people.

I have to mention Junior (Luftwaffe 39-45) for give us permission to use images form his
great website

Finally, i apreciate all people flying campaign day by day. thats all


"IL2" and "IL2 Sturmovik" are trademarks of Ilyushin Aviaton Complex 
(as stands in IL2-FB game manual, page 63) used with permision by 1C:Maddox. 
"IL2-Sturmovik Forgotten Battles" is a tardemark of UBI SOFT.
HyperLobby 2000-2003 Jiri Fojtasek 
(c) VEF 2003 Toronto Irkutsk New York  Moscow. For all questions contact Starshoy (starshoy@rogers.com)

Bellum campaign is running under badc (bourne again dynamic campaign) software.
All original content is Copyright 2003, 2004 by JG10r_Dutertre. All Rights Reserved.
Other content is Copyright its respective owners.


# E- LICENSE



BADC 1.0  - License
Copyright (c) 2003, 2004, JG10r_Dutertre  - ignacio_xxi@hotmail.com
All rights reserved. Licenced under Non-copyleft - see Aditional Notes.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.


Disclaimer:

THIS SOFTWARE IS PROVIDED BY JG10r_Dutertre "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL JG10r_Dutertre BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
END OF TERMS AND CONDITIONS


Aditional NOTES

How to apply these terms to Your new programs.

Case 1) You use this software as is, without modifications. Nothing has to be done, just
agree with this license.

Case 2) You change sources, customize them, improve them, make bug fixes:

2.a) You keep your changes with exactly same Non-copileft licence: Replace
"JG10r_Dutertre" with your name or company name on above licence and replace
software name and version to the name you like different to "BADC 1.0".

2.b) You like to make your changes meet GNU licence: Usually this means you will add
the GNU licence (copyleft), and this avoid futher usage on binay only
distributions or comercial usage. Since this is in oposite to the initial licence,
you have to mention that parts of your release is based on Non-copyleft
license. This way people interested on use code for a binary/comercial
distribution can reach the original source to include in their proyect. To
acomplish this just place somewhere on your documentation that your code includes
Non-copyleft sources, and below that, include the initial licence, printed above.

2.c) You make a comercial or only binary use of this sources: Just mention the
copyright notice when you program runs, like is explained on licence. Because code
of comercial or binary only distributions are out public domain, you have to
mention that parts of your release is based on Non-copyleft license. This way
people interested on use code for other binary/comercial distribution or public
source distributions can reach the original source to include in their proyect. To
acomplish this just place somewhere on your documentation that your code includes
Non-copyleft sources, and below that, include the initial licence, printed above.