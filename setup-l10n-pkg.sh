#!/bin/sh

# make the parent directory above this file's location the current working directory
cd "$(cd -P -- "$(dirname -- "$0")/.." && pwd -P)"

VVV=`head -1 debian-l10n/debian/changelog | sed 's/^.*(\(.*\)).*$/\1/'`

rm -rf fieldworks-l10n-$VVV
mkdir -p fieldworks-l10n-$VVV

cp -p environ fieldworks-l10n-$VVV/environ
echo '# localization does not need xulrunner' > fieldworks-l10n-$VVV/environ-xulrunner
cp -p debian-l10n/Makefile-l10n fieldworks-l10n-$VVV/Makefile

mkdir -p fieldworks-l10n-$VVV/Bin
mkdir -p fieldworks-l10n-$VVV/DistFiles
mkdir -p "fieldworks-l10n-$VVV/DistFiles/Language Explorer/Configuration"
mkdir -p "fieldworks-l10n-$VVV/DistFiles/Translation Editor"

cp -p Bin/abs.py fieldworks-l10n-$VVV/Bin
cp -p Bin/LocaleStrings.exe fieldworks-l10n-$VVV/Bin
cp -p Bin/Po2Xml.exe fieldworks-l10n-$VVV/Bin
cp -p Bin/ProcessLanguagesBld.exe fieldworks-l10n-$VVV/Bin
cp -pR Bld fieldworks-l10n-$VVV
cp -pR Build fieldworks-l10n-$VVV
cp -p "DistFiles/Language Explorer/Configuration/strings-en.xml" "fieldworks-l10n-$VVV/DistFiles/Language Explorer/Configuration"
cp -p "DistFiles/Translation Editor"/BiblicalTerms-*.xml "fieldworks-l10n-$VVV/DistFiles/Translation Editor"
cp -pR Localizations fieldworks-l10n-$VVV
cp -pR Src fieldworks-l10n-$VVV

mkdir -p fieldworks-l10n-$VVV/debian
cp -pR debian-l10n/debian/* fieldworks-l10n-$VVV/debian

# customize the debian/control file and create any needed .install files
# according to the available localization information.
LOCALIZATIONS=`ls Localizations/messages.*.po | sed 's/^.*messages\.\([^.]*\)\.po/\1/'`
for xx in $LOCALIZATIONS; do
	PACKAGETAG=`echo $xx | tr [:upper:] [:lower:]`
	# get the language name from the ISO 639 data file
	LANGUAGE=`grep '\s'$xx'\s' DistFiles/Ethnologue/iso-639-3_*.tab | cut -f7`
	if [ "$LANGUAGE" = "" ]; then
	   # try stripping off any country, script, or variant codes
	   tag=`echo $xx | sed s/-.*$//`
	   LANGUAGE=`grep '\s'$tag'\s' DistFiles/Ethnologue/iso-639-3_*.tab | cut -f7`
	   if [ "$LANGUAGE" = "" ]; then
		  # assume we must have a 3-letter code.
		  LANGUAGE=`grep ^$tag'\s' DistFiles/Ethnologue/iso-639-3_*.tab | cut -f7`
	   fi
	fi
	if [ "$LANGUAGE" = "" ]; then
	   echo "Cannot determine language name for $xx! ..." >&2
	   LANGUAGE=$xx
	fi

	cat >>fieldworks-l10n-$VVV/debian/control <<-EOF
		Package: fieldworks-l10n-$PACKAGETAG
		Architecture: all
	EOF
	if [ -f debian-l10n/$PACKAGETAG.depends ]; then
		cat debian-l10n/$PACKAGETAG.depends >>fieldworks-l10n-$VVV/debian/control
	else
		echo 'Depends: ${misc:Depends}'>>fieldworks-l10n-$VVV/debian/control
	fi
	cat >>fieldworks-l10n-$VVV/debian/control <<-EOF
		Recommends: fieldworks-applications
		Description: FieldWorks user interface localization into $LANGUAGE.
		 FieldWorks is a suite of software tools to help language development teams
		 manage language and cultural data, with support for complex scripts.
		 .
		 For further information, please visit http://fieldworks.sil.org/

	EOF
	cat >fieldworks-l10n-$VVV/debian/fieldworks-l10n-$PACKAGETAG.install <<-EOF
		usr/lib/fieldworks/$xx/*.resources.dll usr/lib/fieldworks/$xx
		usr/share/fieldworks/Language?Explorer/Configuration/strings-$xx.xml
	EOF
done

tar czf fieldworks-l10n_$VVV.orig.tar.gz fieldworks-l10n-$VVV

# finally, build the source package
cd fieldworks-l10n-$VVV
debuild -S
