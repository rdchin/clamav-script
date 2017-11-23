#!/bin/bash
VERSION="2017-08-05 18:22"
#
#@ Code Change History
#@
#@ 2017-08-05 - *Main Program changed option "Show only infected files" so it
#@               is not verbose.
#@              *Main Program added f_abort_txt message if ended with errors.
#@              *f_show_common created to reduce duplicated code.
#@
#@ 2017-05-10 *Main Program added option to update virus definitons
#@             via freshclam.
#@            *Main Program added detection of valid arguments.
#@            *f_arguments added to detect valid arguments "--version",
#@             "--about", and "--history".
#@            *f_help_message_txt added to allow the argument "--help"
#@             to invoke a help message.
#@            *f_script_path added.
#@
#@ 2017-02-09 *f_show_only_infected_txt, f_show_all_txt improved readabilty of
#@             display of command and options.
#@
#@ 2017-02-08 *Main Program checked if $FILE_VIEWER application is
#@             installed by using "test" instead of "eval" command.
#@
#@ 2017-01-27 - *Main Program added check for clamav installed.
#@               Added option to update virus definitons via freshclam.
#@
#@ 2017-01-25 - *Improved messages added start/end times.
#@
#@ 2017-01-23 - *Rewrote script to include option to show all/only infected files.
#@
#@ 2016-09-06 - *Added list of infected files and errors at end of $LOG_FILE.
#
# +----------------------------------------+
# |         Function f_show_common         |
# +----------------------------------------+
#
#  Inputs: $1=clamscan OPTIONS string.
#          $2=Directory to be scanned.
#    Uses: X, START_TIME, OPTIONS.
# Outputs: None.
#
f_show_common () {
       START_TIME=$(date)
       # Substitute <space> for "_" in string $1.
       OPTIONS=$(echo $1 | tr '_' ' ')
       #
       echo $(tput bold)
       echo "Command: sudo clamscan $OPTIONS --log=$LOG_FILE $2"
       echo $(tput sgr0) # Set font to normal color.
       echo "              OPTIONS: -r Recursive to sub-directories."
       echo "                       -v Verbose reporting."
       echo "                       -i Only print infected files." 
       echo
       echo -n "Does the command look OK? (Y/n/(q)uit): " ; read X
       case $X in
            [Nn] | [Nn][Oo]) f_abort_txt
            ;;
            [Qq] | [Qq][Uu] | [Qq][Uu][Ii] | [Qq][Uu][Ii][Tt]) f_abort_txt
            ;;
       esac
       echo
       echo "The screen may look like nothing is happening but please be patient."
       echo "The scan may take a long time."
       echo "Please wait..."
       echo
       sudo clamscan $OPTIONS --log="$LOG_FILE" $2
       echo >>$LOG_FILE
       echo >>$LOG_FILE
       clamscan --version >>$LOG_FILE
       echo "------------------------------------------------------------------------------" >>$LOG_FILE
       echo "Scan directory: $2" >>$LOG_FILE
       echo "Started on: $START_TIME" >>$LOG_FILE
       echo -n "  Ended on: " >>$LOG_FILE ; date>>$LOG_FILE
       echo >>$LOG_FILE
       unset X
}  # End of function f_show_common
#
# +----------------------------------------+
# |      Function f_show_only_infected     |
# +----------------------------------------+
#
#  Inputs: None.
#    Uses: LOG_FILE.
# Outputs: None.
#
f_show_only_infected () {
       echo
       echo "See log file for more details at $LOG_FILE"
       
}  # End of function f_show_only_infected
#
# +----------------------------------------+
# |          Function f_show_all           |
# +----------------------------------------+
#
#  Inputs: None.
#    Uses: X, START_TIME, OPTIONS, LOG_FILE, LOG_FILE_TMP.
# Outputs: None.
#
f_show_all () {
       echo "List of infected files below:" >>$LOG_FILE
       grep FOUND $LOG_FILE >$LOG_FILE_TMP
       cat $LOG_FILE_TMP >>$LOG_FILE
       echo "<<End of list of infected files>>" >>$LOG_FILE
       echo >>$LOG_FILE
       echo >>$LOG_FILE
       echo "------------------------------------------------------------------------------" >>$LOG_FILE
       echo "List of errors below:" >>$LOG_FILE
       grep ERROR $LOG_FILE >$LOG_FILE_TMP
       cat $LOG_FILE_TMP >>$LOG_FILE
       echo >>$LOG_FILE
       echo "<<End of list of errors>>" >>$LOG_FILE
       echo
       echo "See log file for more details at $LOG_FILE"
}  # End of function f_show_all
#
# +----------------------------------------+
# |            Function f_abort_txt        |
# +----------------------------------------+
#
#  Inputs: None.
#    Uses: None.
# Outputs: None.
#
f_abort_txt() {
      echo $(tput setaf 1) # Set font to color red.
      echo -n $(tput bold)
      echo >&2 "***************"
      echo >&2 "*** ABORTED ***"
      echo >&2 "***************"
      echo
      echo "An error occurred. Exiting..." >&2
      exit 1
      echo -n $(tput sgr0) # Set font to normal color.
} # End of function f_abort_txt.
#
# +----------------------------------------+
# |           Start of Main Program        |
# +----------------------------------------+
#
# Does clamav log directory exist?
if [ ! -d "/var/log/clamav" ] ; then  # If directory does not exist...
   echo -n $(tput setaf 1) # Set font to color red.
   echo -n $(tput bold)
   echo "Error: The directory /var/log/clamav does not exist."
   echo "Is clamav installed properly?"
   f_abort_txt
fi
#
clamscan --version  # Display on-screen the version of clamav.
echo -n "Before scanning for viruses, do you want to update the virus definitions? (Y/n/quit): " ; read X
case $X in
     [Nn] | [Nn][Oo])
     ;;
     [Qq] | [Qq][Uu] | [Qq][Uu][Ii] | [Qq][Uu][Ii][Tt]) f_abort_txt
     ;;
     *) echo ; echo
        sudo freshclam
        ERROR=$?
        if [ $ERROR -ne 0 ] ; then
           echo -n $(tput setaf 1) # Set font to color red.
           echo -n $(tput bold)
           echo "Error: Failed to update virus definitions."
           f_abort_txt
        fi
     ;;
esac
echo
echo
echo "Clam anti-virus scanning script:"
echo "virusscan_clamav.sh $VERSION"
echo
SCAN_DIR=$1
if [ -n "$SCAN_DIR" ] && [ -d "$SCAN_DIR" ] ; then  # If $SCAN_DIR is non-null and is a legitimate directory...
   echo "Scan directory:"
   echo "$SCAN_DIR"
   echo
   DATE=`date`
   #
   LOG_FILE="/var/log/clamav/$(date +%Y%m%d-%H%M)_clamscan_report.log"
   LOG_FILE_TMP="/var/log/clamav/list_infected_files.tmp"
   echo "Log file:"
   echo "$LOG_FILE."
   echo
   echo "Scan directory: $SCAN_DIR started on: ">>$LOG_FILE ; date>>$LOG_FILE
   ERROR=$?  # Was "sudo" included in command "sudo bash virusscan_clamav.sh <DIRECTORY>"?
   if [ $ERROR -eq 0 ] ; then
      echo
      echo
      echo -n "Scan also the sub-directories below $1? (Y/n/quit): "; read X
      case $X in
           [Nn] | [Nn][Oo]) OPTIONS=""
           ;;
           [Qq] | [Qq][Uu] | [Qq][Uu][Ii] | [Qq][Uu][Ii][Tt]) f_abort_txt
           ;;
           *) OPTIONS="-r"
           ;;
      esac
      echo -n "Show only infected files? (Y/n/quit): " ; read X
      echo
      case $X in
           [Nn] | [Nn][Oo]) 
	   # echo "OPTIONS=$OPTIONS"  # Diagnostic line.
	   OPTIONS=$OPTIONS"_-v" 
	   f_show_common $OPTIONS $SCAN_DIR
	   f_show_all 
	   ;;
           [Qq] | [Qq][Uu] | [Qq][Uu][Ii] | [Qq][Uu][Ii][Tt])
           f_abort_txt
	   ;;
           *) 
	   # echo "OPTIONS=$OPTIONS"  # Diagnostic line.
	   OPTIONS=$OPTIONS"_-i"
	   f_show_common $OPTIONS $SCAN_DIR
	   f_show_only_infected
	   ;;
      esac
      unset X START_TIME OPTIONS
      echo
      echo -n "Look at log file? (Y/n/quit): " ; read X
      case $X in
           [Nn] | [Nn][Oo])
	   ;;
           [Qq] | [Qq][Uu] | [Qq][Uu][Ii] | [Qq][Uu][Ii][Tt])
           f_abort_txt
	   ;;
           *)
           # Detect installed file viewer/pager.
           RUNAPP=0
           for FILE_VIEWER in most more less
           do
               if [ $RUNAPP -eq 0 ] ; then
                  eval $FILE_VIEWER
                  ERROR=$?
                  if [ $ERROR -eq 0 ] ; then
                     eval $FILE_VIEWER $LOG_FILE
                     RUNAPP=1   
                  fi
               fi
           done
	   ;;
      esac
   else
      echo -n $(tput setaf 1) # Set font to color red.
      echo -n $(tput bold)
      echo
      echo "Need \"sudo\" permission."
      echo
      echo "Usage: sudo bash viruscan_clamav.sh <DIRECTORY TO BE SCANNED>"
      echo
      f_abort_txt
   fi
else
   echo -n $(tput setaf 1) # Set font to color red.
   echo -n $(tput bold)
   echo "Missing or invalid <DIRECTORY TO BE SCANNED>."
   echo
   echo "Usage: sudo bash viruscan_clamav.sh <DIRECTORY TO BE SCANNED>"
   echo
   f_abort_txt
fi
# All dun dun noodles.
