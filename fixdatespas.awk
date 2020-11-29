# Fix the timestamps inside .PAS files
# PMS 29-November-2020 21:02

# Line 2 of .PAS files contains a hand-edited date in a comment:
# { PMS 2-February-1990 23:15 }
# or
# { PMS 28 Nov 2020 18:30 }
# but this is often out of date. This code sets it to be the actual timestamp of the file

# Note that this is *opposite* of fixdatearc.awk which sets the file timestamp to the
# time written in the comment.
# Philip Sargent  29 November 2020

BEGIN	{
	n = split("January February March April May June July August September October November December", mnthname);
}

BEGINFILE	{ 	
		cmd = "touch " FILENAME ".sub"
		system(cmd)
}

/\{ PMS/	{
	# read the comment on line 2
	gsub(/-/," ");
	day = $3
	month = $4
	year = $5
	t = $6
	comment =  "\"PMS " day " " month " " year " " t "\""
	
	# get the timestamp of the file we are reading
	("ls  --full-time " FILENAME ) | getline lsline
	split(lsline,a," ");
	fdate = a[6];
	ftime = a[7];
	ftz = a[8]
	split(fdate,b,"-")
	fyear = b[1]
	monthnum = b[2]
	fmonth = mnthname[monthnum]
	fday = b[3]
	split(ftime,c,":")
	fhours = c[1]
	fmins = c[2]
	fsecs = substr(c[3],1,2)
	timestamp =  fday "-"  fmonth "-" fyear " " fhours ":" fmins ":" fsecs 
	newcomment = "{ PMS " timestamp " }"
	print FILENAME, "\t" comment, "->\t" newcomment
	
	print newcomment > FILENAME ".sub" 
	next
}

//	{ 
	print > FILENAME ".sub" 
}

# the end after ALL the files have been read as specified on the awk command line
ENDFILE	{	
	if (newcomment != "") {
		cmd = "touch " FILENAME ".sub -c -d \"" timestamp "\""
		system(cmd) 
		cmd = "mv " FILENAME ".sub " FILENAME
		system(cmd) 		
	} else {
		print "No timestamp found."
	}
}





