#!/usr/bin/env bash

set -x

#FROM i2incommon/shib-idp:4.1.0_20210324
#ENV 

OIDC_COMMON_VERSION=1.1.0 
OIDC_OP_VERSION=3.0.0 
DUO_OIDC_VERSION=1.1.1

#ENV 
SHIB_OIDC_COMMON_RELDIR=https://shibboleth.net/downloads/identity-provider/plugins/oidc-common 
SHIB_OIDC_COMMON_PREFIX=oidc-common-dist 
SHIB_OIDC_OP_RELDIR=https://shibboleth.net/downloads/identity-provider/plugins/oidc-op 
SHIB_OIDC_OP_PREFIX=idp-plugin-oidc-op-distribution 
SHIB_DUO_NIMBUS_RELDIR=https://shibboleth.net/downloads/identity-provider/plugins/duo-oidc 
SHIB_DUO_NIMBUS_PREFIX=idp-plugin-duo-nimbus-dist

# Create install directory and download plugins

#RUN 
mkdir -p /tmp/idp-plugins && cd /tmp/idp-plugins && \
    wget -q https://shibboleth.net/downloads/PGP_KEYS && \
    wget -N -q $SHIB_OIDC_COMMON_RELDIR/$OIDC_COMMON_VERSION/$SHIB_OIDC_COMMON_PREFIX-$OIDC_COMMON_VERSION.tar.gz && \
    wget -N -q $SHIB_OIDC_COMMON_RELDIR/$OIDC_COMMON_VERSION/$SHIB_OIDC_COMMON_PREFIX-$OIDC_COMMON_VERSION.tar.gz.asc && \
    wget -N -q $SHIB_OIDC_OP_RELDIR/$OIDC_OP_VERSION/$SHIB_OIDC_OP_PREFIX-$OIDC_OP_VERSION.tar.gz && \
    wget -N -q $SHIB_OIDC_OP_RELDIR/$OIDC_OP_VERSION/$SHIB_OIDC_OP_PREFIX-$OIDC_OP_VERSION.tar.gz.asc && \
    wget -N -q $SHIB_DUO_NIMBUS_RELDIR/$DUO_OIDC_VERSION/$SHIB_DUO_NIMBUS_PREFIX-$DUO_OIDC_VERSION.tar.gz && \
    wget -N -q $SHIB_DUO_NIMBUS_RELDIR/$DUO_OIDC_VERSION/$SHIB_DUO_NIMBUS_PREFIX-$DUO_OIDC_VERSION.tar.gz.asc 
    #exit
# Install
    cd /opt/shibboleth-idp && \
    bin/module.sh -e idp.intercept.Consent && \
    bin/plugin.sh --noPrompt --truststore /tmp/idp-plugins/PGP_KEYS -i /tmp/idp-plugins/$SHIB_OIDC_COMMON_PREFIX-$OIDC_COMMON_VERSION.tar.gz && \
    bin/plugin.sh --noPrompt --truststore /tmp/idp-plugins/PGP_KEYS -i /tmp/idp-plugins/$SHIB_OIDC_OP_PREFIX-$OIDC_OP_VERSION.tar.gz && \
    bin/plugin.sh --noPrompt --truststore /tmp/idp-plugins/PGP_KEYS -i /tmp/idp-plugins/$SHIB_DUO_NIMBUS_PREFIX-$DUO_OIDC_VERSION.tar.gz 
# Cleanup

