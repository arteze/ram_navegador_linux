#!/bin/sh

# pcompress modificado para comprimir con ia64 y diferenciar .gz.sfs de .xz.sfs

export debug=0 #1 0

if [ -f /usr/share/pixmaps/puppy/package_add.png ] ; then
	cambiar_icono.sh /usr/share/pixmaps/puppy/package_add.png
fi

#inputfile
if [ "$1" = "" ]; then #no args, no file
	export inputfile=$(yad --title="Open File" --file --filename="$pwd" --width="640" --height="480" --center --on-top --sticky --borders="4" $ZICON)
	[ ! "$inputfile" ] && echo "User cancelled operation" && exit 1
else
	export inputfile="$@" #file was specified in the args
fi
[ ! -e "$inputfile" ] && yad --title="Error" --text="File does not exist:\n\n$inputfile" --image="dialog-error" --button="OK":0 --center --on-top --fixed --sticky --borders="4" $ZICON && exit 1

inputfile=$(realpath "$inputfile")

#############################################/root/file.tar.gz
filenopath="${inputfile##*/}"				#file.tar.gz
fileext="${filenopath##*.}"					#gz
filenoext="${filenopath/%.$fileext/}"		#file.tar
fileext2="${filenoext##*.}"					#tar
__rootname="${filenopath%%.*}"				#file

if [ $debug -eq 1 ] ; then
	echo "filenopath $filenopath"
fi

inputdir=${inputfile%/*}
[[ $inputdir == */ ]] && inputdir=${inputdir%\/}
export outputdir="$inputdir"

#===============================================================
#                      MAIN DIALOG
#===============================================================

CONFIGFILE=${HOME}/.config/pcompress
[ -f $CONFIGFILE ] && . $CONFIGFILE

#YAD: --field=":CB" "value1!value2!^defaultvalue3!value4!......"
if [ "$(type 7z 2>/dev/null)" ] ; then
	formatstr=".7z     0%!.7z     50%!.7z     100%!"
fi
if [ "$(which tar 2>/dev/null)" ] ; then
	formatstr+=".tar!.tar.gz!.tar.xz!.tar.zst!"
fi
if [ "$(which zip 2>/dev/null)" ] ; then
	formatstr+=".zip     50%!.zip     100%!"
fi
if [ "$(which mksquashfs 2>/dev/null)" ] ; then
	formatstr+=".gz.sfs gzip!"
	formatstr+=".xz.sfs xz!"
fi

if [ -d "$inputfile" ] ; then
	labelx="Dir:"
	formatstr+="!.iso"
else
	labelx="File:"
	[ "$defaultformat" = ".iso" ] && defaultformat=''
fi

if ! [ "$defaultformat" ] ; then
	defaultformat='.tar.gz'
fi

if [ $debug -eq 1 ] ; then
	echo "formatstr $formatstr"
fi

formatstr=${formatstr%\!}
if [ "$outformatcli" ] ; then
	formatstr=${formatstr//${defaultformat}/^${outformatcli}}
else
	formatstr=${formatstr//${defaultformat}/^${defaultformat}}
fi

[ ! "$defaultsplitvalue" ] || [ ! $defaultsplitvalue -ge 1 ] && defaultsplitvalue="100"

dialog_result="$(yad --title="$labelx $inputfile" $ZICON \
	--center --fixed --borders="4" --buttons-layout="center" \
	--columns=2 --separator="|" --form  \
	--field="Output file:" "$filenopath" \
	--field="Location::DIR" "$outputdir" \
	--field="Password (7z)::H" "" \
	--field="Password (7z)::H" "" \
	--field="Generate .md5.txt file:CHK" "FALSE" \
	--field=":CB" "$formatstr"  \
	--field="Encrypt file list (passwd) (7z):CHK" "FALSE" \
	--field="Split into volumes of MB (7z)::CHK" "FALSE" \
	--field=":NUM" "$defaultsplitvalue" \
	--field="Generate .sha256.txt file:CHK" "FALSE" \
	--button="<b>C_reate</b>:0" \
	--button="gtk-close:10" --dialog-sep --buttons-layout=end )"
[ $? -ne 0 ] || [ "$dialog_result" = "" ] && echo "User cancelled operation" >&2 && exit 1

#==============================================================

#                   1           2        3      4     5        6           7       8     9          10
IFS="|" read -r outfilename outputdir  pass1  pass2   md5   outformat  hidefiles  split  splitvalue  sha256 <<< "$dialog_result"
#echo read -r $outfilename $outputdir $pass1 $pass2  $md5  $outformat $hidefiles $split $splitvalue $sha256

if [ $debug -eq 1 ] ; then
	echo "------- Depurando -------"
	echo "dialog_result $dialog_result"
	echo "outfilename $outfilename"
	echo "outputdir $outputdir"
	echo "pass1 $pass1"
	echo "pass2 $pass2"
	echo "md5 $md5"
	echo "outformat $outformat"
	echo "hidefiles $hidefiles"
	echo "split $split"
	echo "splitvalue $splitvalue"
	echo "sha256 $sha256"
	echo "----- Fin Depurando -----"
fi

SPLITVALUE=
PASSWORD=
HIDEFILES=

if [ "$split" = "TRUE" ] ; then
	splitvalue=${splitvalue//.000000}
	SPLITVALUE=${splitvalue//,000000}
fi

echo "defaultformat='$outformat'
defaultsplitvalue='$splitvalue'" > $CONFIGFILE

case $outformat in *.zip*|*.7z*)
	if  [ "$pass1" ] || [ "$pass2" ] ; then
		if [ "$pass1" = "$pass2" ] ; then
			PASSWORD="${pass1}"
		else
			res=$(yad --title="Error" --image="dialog-error" --text="Passwords do not match, re-enter here" --entry --center --fixed $ZICON)
			[ ! "$res" ] && echo "User cancelled operation" >&2 && exit 1
			PASSWORD="${res}"
		fi
	fi
esac

case $outformat in *.7z*)
	if  [ "$hidefiles" = "TRUE" ] && [ ! "$PASSWORD" ]; then
		res=$(yad --title="Error" --image="dialog-error" --entry --center --fixed \
		--text="Filename encryption is enabled, which means that you have to specify a password..." $ZICON)
		[ ! "$res" ] && echo "User cancelled operation" >&2 && exit 1
		PASSWORD="${res}"
		HIDEFILES='yes'
	elif  [ "$hidefiles" = "TRUE" ] ; then
		HIDEFILES='yes'
	fi
esac

export outformat outputdir inputdir inputfile filenopath
export SPLITVALUE PASSWORD HIDEFILES
[ "$outputdir" = "/" ] && outputdir=""
export OUTPUTFILENAME="${filenopath}${outformat%% *}"
export OUTPUTFILE="${outputdir}/${OUTPUTFILENAME}"
export md5 sha256

z="${outformat##* }"
salida="$outputdir/$outfilename.$z.sfs"
if [ $debug -eq 1 ] ; then
	echo "outformat: $outformat"
	echo "z: $z"
	echo "Salida: $salida"
fi
if [ -f "$salida" ] ; then
	yad --image="dialog-question" --title "File exists" $ZICON \
	--button=gtk-yes:0 --button=gtk-no:1 \
	--text="File: \n\n $salida \n\n already exists. Replace it?   " \
	--center --sticky --borders=4
	if [ $? -eq 0 ] ; then
		rm -fv "$salida"
	else
		exit
	fi
fi

if [ "$outformat" = ".iso" ] ; then
	exec dir2iso "$inputfile" "$OUTPUTFILE"
fi

function pcompressScript() {
	cd "$inputdir" #where the input *file is. [*file=file/dir]

	INPUTFILE="$filenopath"
	salida="$1"
	entrada="$inputdir/$INPUTFILE"

	if [ $debug -eq 1 ] ; then
		echo "inputdir $inputdir"
		echo "INPUTFILE $INPUTFILE"
		echo "outformat $outformat"
	fi
	case $outformat in
		.tar*) #SAFE FOR USE WITH LINUX IN GENERAL
			tarcomp="-vcf"
			case $outformat in
				.tar.gz) tarcomp="-vzcf" ;;
				.tar.xz) tarcomp="-vJcf" ;;
				.tar.zst) tarcomp="--zstd -vcf" ;;
			esac
			#tar -vzcf /pathto/filenopath.tar inputfile-no-path
			PROG="tar $tarcomp"
		;;
		.zip*) #DO NOT USE WITH SYMLINKS
			[ "$PASSWORD" ] && zippass="-P $PASSWORD"
			z=${outformat##* }
			case $z in
				50%)  zipcomp='-5' ;;
				100%) zipcomp='-9' ;;
			esac
			#zip -rv -5 -P password	/pathto/outfile.zip	infile-no-path
			PROG="zip -rv $zipcomp $zippass"
		;;
		.7z*) #DO NOT USE WITH SYMLINKS
			z=${outformat##* }
			case $z in
				0%)   zcomp='-mx0' ;;
				50%)  zcomp='-mx5' ;;
				100%) zcomp='-mx9' ;;
			esac
			[ "$PASSWORD" ] && zpass="-p${PASSWORD}"
			[ "$HIDEFILES" ] && zhidefiles="-mhe"
			[ "$SPLITVALUE" ] && [ $SPLITVALUE -ge 1 ] && zplit="-v${SPLITVALUE}m"
			[ "$outputdir" = "/" ] && outputdir=""
			cd "$inputdir"
			#7z a -t7z -mx9 -pASSWORD -mhe -v100m /path/to/file.7z "infile no path"
			PROG="7z a -t7z $zcomp $zpass $zhidefiles $zplit"
		;;
		*.sfs*)
			# mksquashfs input output.sfs -comp xx
			z=${outformat##* }
			sfscomp="-comp $z"
			PROG="mksquashfs"
			OPTS_END=" -noappend $sfscomp -b 1M -Xbcj ia64"
			INPUTFILE="${OUTPUTFILE}"
			OUTPUTFILE="$filenopath"
			if [ $debug -eq 1 ] ; then
				echo "sfscomp $sfscomp"
				echo "z $z"
				echo "linea $LINENO ... INPUTFILE $INPUTFILE"
				echo "linea $LINENO ... OUTPUTFILE $OUTPUTFILE"
				echo "linea $LINENO ... outfilename $outfilename"
			fi
		;;
	esac
	if [ $debug -eq 1 ] ; then
		echo "OUTPUTFILE: $OUTPUTFILE"
	fi
	echo ""
	if ! [ "$PASSWORD" ] || [ $debug -eq 1 ] ; then
		echo $PROG $OPTS "$entrada" "$salida" $OPTS_END
		echo
	fi
	$PROG $OPTS "$entrada" "$salida" $OPTS_END
	exitcode=$?
	if [ $exitcode -ne 0 ]; then
		echo
		echo "Exit code: $exitcode"
		echo -n 'THERE WAS AN ERROR. PRESS ENTER KEY TO CLOSE THIS WINDOW: '
		read var #read -t 30 var (timeout)
	else
		if [ "$md5" = "TRUE" ] ; then
			echo "Generating ${OUTPUTFILENAME}.md5.txt"
			md5sum "$OUTPUTFILENAME" > "${OUTPUTFILENAME}.md5.txt"
		fi
		if [ "$sha256" = "TRUE" ] ; then
			echo "Generating ${OUTPUTFILENAME}.256.txt"
			sha256sum "$OUTPUTFILENAME" > "${OUTPUTFILENAME}.sha256.txt"
		fi
	fi
	if [ $debug -eq 1 ] ; then
		echo -en "debug mode, hit enter to continue.. " && read aaa #DEBUG
	else
		sleep 1.5
	fi
	exit
}
export -f pcompressScript

xdotool getactivewindow set_window --name "Creando '$salida'"
pcompressScript "$salida"

### END ###
