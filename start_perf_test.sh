#!/bin/bash

_=${KCB_USERS_PER_SEC:=1}
_=${KCB_USERS_PER_REALM:=1}
_=${KCB_MEASUREMENT:=30}
_=${KCB_SCENARIO:="keycloak.scenario.authentication.AuthorizationCode"}
_=${KCB_USER_THINK_TIME:="0"}
_=${KCB_REALM_NAME:="realm-0"}
_=${KCB_USE_INCREMENT:="false"}
_=${KCB_INCREMENT:="32"}
_=${KCB_RAMP_UP:="5"}
_=${KCB_WARM_UP:="0"}
_=${KCB_SLA_ERROR_PERCENTAGE:="0"}
_=${KCB_SLA_MEAN_RESPONSE_TIME:="300"}
_=${KCB_USE_ALL_LOCAL_ADDRESSES:="false"}
_=${KCB_FILTER_RESULTS:="false"}

prefix=KCB_
typeset -p | awk '$3 ~ "^"pfx { print $3 }' pfx="$prefix" 

if [[ -z "${KC_SERVER_URL}" ]]; then
  echo "Environment variable 'KC_SERVER_URL' is not set"
  exit 1
fi

if [[ -z "${KC_ADMIN_USERNAME}" ]]; then
  echo "Environment variable 'KC_ADMIN_USERNAME' is not set"
  exit 1
fi

if [[ -z "${KC_ADMIN_PASSWORD}" ]]; then
  echo "Environment variable 'KC_ADMIN_PASSWORD' is not set"
  exit 1
fi

PATH=$PATH:/opt/keycloak/bin:/opt/keycloak-benchmark/bin

# Start apache server and update page periodically with links for results
cd /opt/keycloak-benchmark/results
source collect_results.sh
/usr/sbin/httpd

# Login to Keycloak
kcadm.sh config credentials \
  --server ${KC_SERVER_URL} \
  --realm master \
  --user "${KC_ADMIN_USERNAME}" \
  --password "${KC_ADMIN_PASSWORD}"

# Start performance tests
if [ "$KCB_USE_INCREMENT" = true ]; then
  KCB_INCREMENT="--increment=$KCB_INCREMENT"
else
  KCB_INCREMENT=""
fi

kcb.sh \
    --server-url="${KC_SERVER_URL}" \
    --realm-name="${KCB_REALM_NAME}" \
    --users-per-realm=$KCB_USERS_PER_REALM \
    --measurement=$KCB_MEASUREMENT \
    --users-per-sec=$KCB_USERS_PER_SEC \
    --scenario="${KCB_SCENARIO}" \
    --user-think-time=$KCB_USER_THINK_TIME \
    --sla-error-percentage=$KCB_SLA_ERROR_PERCENTAGE \
    --sla-mean-response-time=${KCB_SLA_MEAN_RESPONSE_TIME} \
    $KCB_INCREMENT \
    --ramp-up=$KCB_RAMP_UP \
    --warm-up=$KCB_WARM_UP \
    --use-all-local-addresses=${KCB_USE_ALL_LOCAL_ADDRESSES} \
    --filter-results=${KCB_FILTER_RESULTS}

# Wait for SIGTERM
trap 'trap - TERM; kill -s TERM -- -$$' TERM
tail -f /dev/null & wait
exit 0
