#!/bin/bash 
#
# A tool used to fetch an LDAP directory's SSL certificate and load it into a Java keystore
#
# Author: Chris Phillips chris.phillips@canarie.ca / twitter:@teamktown
# Date: June 2, 2015
# Updated: Aug, 2021 - author aligned to Apache2 licensing
#
# It is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

die() { echo "$@" 1>&2 ; exit 1; }
[ "$#" -eq 1 ] || die "Usage: certRefresh.sh <FQDN.of.your.directory.org>"

ldapserver="${1}"
statusFile="status.log"

setEcho() {
	Echo=""
	if [ -x "/bin/echo" ]; then
		Echo="/bin/echo -e"
	elif [ -x "`which printf`" ]; then
		Echo="`which printf` %b\n"
	else
		Echo="echo"
	fi

	#${Echo} "echo command is set to be '${Echo}'"
}

setMyEnv ()
{


	resultCAcerts="latest-cacerts"
	certpath="/tmp/$$"
}

setJavaCACerts ()

{
	javaCAcerts="${JAVA_HOME}/lib/security/cacerts"
	keytool="${JAVA_HOME}/bin/keytool"
}

createCertificatePathAndHome ()

{

mkdir -p ${certpath}
	

}
configShibbolethSSLForLDAPJavaKeystore()

{

# 	Fetch certificates from LDAP servers
	lcnt=1
	capture=0
	ldapCert="ldapcert.pem"
	${Echo} 'Fetching and installing certificates from LDAP server(s)'
	for i in `${Echo} ${ldapserver}`; do
		#Get certificate info
		${Echo} "QUIT" | openssl s_client -showcerts -connect ${i}:636 > ${certpath}${i}.raw 2>&1
		files="`${Echo} ${files}` ${certpath}${i}.raw"

		for j in `cat ${certpath}${i}.raw | sed -re 's/\ /\*\*\*/g'`; do
			n=`${Echo} ${j} | sed -re 's/\*\*\*/\ /g'`
			if [ ! -z "`${Echo} ${n} | grep 'BEGIN CERTIFICATE'`" ]; then
				capture=1
				if [ -s "${certpath}${ldapCert}.${lcnt}" ]; then
					lcnt=`expr ${lcnt} + 1`
				fi
			fi
			if [ ${capture} = 1 ]; then
				${Echo} ${n} >> ${certpath}${ldapCert}.${lcnt}
			fi
			if [ ! -z "`${Echo} ${n} | grep 'END CERTIFICATE'`" ]; then
				capture=0
			fi
		done
	done

	numLDAPCertificateFiles=0
	minRequiredLDAPCertificateFiles=1

	for i in `ls ${certpath}${ldapCert}.*`; do

		numLDAPCertificateFiles=$[$numLDAPCertificateFiles +1]
		md5finger=`${keytool} -printcert -file ${i} | grep MD5 | cut -d: -f2- | sed -re 's/\s+//g'`
		test=`${keytool} -list -keystore ${newJavaCAcerts} -storepass changeit | grep ${md5finger}`
		subject=`openssl x509 -subject -noout -in ${i} | awk -F= '{print $NF}'`
		if [ -z "${test}" ]; then
			${Echo} "Keystore: ${newJavaCAcerts} Removing old certificate having alias of: ${subject}"
			${Echo} "Keystore: ${newJavaCAcerts} Removing old certificate having alias of: ${subject}" >> ${statusFile} 2>&1
			${keytool} -delete -alias "${subject}" -keystore ${newJavaCAcerts} -storepass changeit >> ${statusFile} 2>&1
			${Echo} "Keystore: ${newJavaCAcerts} Importing NEW certificate having alias of: ${subject}"
			${Echo} "Keystore: ${newJavaCAcerts} Importing NEW certificate having alias of: ${subject}" >> ${statusFile} 2>&1
			${keytool} -import -noprompt -alias "${subject}" -file ${i} -keystore ${newJavaCAcerts} -storepass changeit >> ${statusFile} 2>&1
		fi
		files="`${Echo} ${files}` ${i}"
	done

	# note the numerical comparison of 
	if [ "$numLDAPCertificateFiles" -ge "$minRequiredLDAPCertificateFiles" ]; then

		${Echo} "Successfully fetched LDAP SSL certificate(s) fetch from LDAP directory." 
		${Echo} "Number loaded: ${numLDAPCertificateFiles} into this keystore ${newJavaCAcerts}"
		${Echo} ""
		${Echo} "To use this new certificate:"
		${Echo} "  1. Review status.log in this directory for any anomalies"
		${Echo} "  2. Backup ${javaCAcerts} to a known location"
		${Echo} "  3. Copy the new keystore over top of old one: cp ${newJavaCAcerts} ${javaCAcerts}"
		${Echo} "  4. Restart your container to recognize the new keystore"
		${Echo} ""	
		${Echo} "Commands to cut and paste to backup and overwrite existing certificate file (run as root):"	
		${Echo} "  cp ${javaCAcerts} ./cert-backups"	
		${Echo} "  cp ${newJavaCAcerts} ${javaCAcerts}"
		${Echo} ""	
		${Echo} "Status.log:"	
		cat status.log
	else
		${Echo} "***SEVERE ERROR*** \n\nAutomatic LDAP SSL certificate fetch from LDAP directory failed!"
		${Echo} "Please ensure the provided FQDN (NOT IP ADDRESS) is resolvable and pingable before starting again"
		exit

	fi
}

# set environment variables
setEcho
setMyEnv
setJavaCACerts

# define the new certificate file
origJavaCAcerts="`pwd`/origcerts.$$"
newJavaCAcerts="`pwd`/newcerts"

# copy the JVM certificate file to local directory as a backup and create the new one we are working on
cp ${javaCAcerts} ${origJavaCAcerts}
cp ${javaCAcerts} ${newJavaCAcerts}

# this connects to the directory server and extracts the relevant certificate
configShibbolethSSLForLDAPJavaKeystore
