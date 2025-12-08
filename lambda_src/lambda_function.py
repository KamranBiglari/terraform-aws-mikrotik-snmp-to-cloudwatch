
import boto3
import os
from datetime import datetime
from pysnmp.hlapi import *

cloudwatch = boto3.client('cloudwatch')

ROUTER_IP = os.environ['ROUTER_IP']
COMMUNITIES = os.environ['SNMP_COMMUNITIES'].split(",")
SNMP_OIDS = os.environ['SNMP_OIDS'].split(",")
CLOUDWATCH_NAMESPACE = os.environ.get('CLOUDWATCH_NAMESPACE', 'MikroTik')
VERBOSE_LOGGING = os.environ.get('VERBOSE_LOGGING', 'false').lower() == 'true'

def log(message):
    if VERBOSE_LOGGING:
        print(message)

def snmp_get(oid, community):
    errorIndication, errorStatus, errorIndex, varBinds = next(
        getCmd(SnmpEngine(),
               CommunityData(community, mpModel=0),  # SNMP v2c
               UdpTransportTarget((ROUTER_IP, 161), timeout=2, retries=2),
               ContextData(),
               ObjectType(ObjectIdentity(oid)))
    )
    if errorIndication:
        log(f"SNMP error with community {community}: {errorIndication}")
        return None
    elif errorStatus:
        log(f"SNMP error status with community {community}: {errorStatus}")
        return None
    else:
        for varBind in varBinds:
            oid_str, value = varBind
            log(f"SNMP GET success: {oid_str} = {value}")
            try:
                return int(value)
            except Exception:
                log(f"Failed to convert value to int for OID {oid_str}: {value}")
                return None

def lambda_handler(event, context):
    log(f"Lambda triggered for router {ROUTER_IP}")
    log(f"Communities to try: {COMMUNITIES}")
    log(f"OIDs to poll: {SNMP_OIDS}")

    working_community = None
    for community in COMMUNITIES:
        log(f"Trying SNMP community: {community}")
        test = snmp_get(SNMP_OIDS[0], community)  # test first OID
        if test is not None:
            working_community = community
            log(f"Using SNMP community: {community}")
            break

    if working_community is None:
        print("Failed to connect using any SNMP community. Exiting Lambda.")
        return

    for oid in SNMP_OIDS:
        value = snmp_get(oid, working_community)
        if value is not None:
            metric_name = oid.replace(".", "_")
            log(f"Pushing to CloudWatch: {CLOUDWATCH_NAMESPACE} / {metric_name} = {value}")
            try:
                cloudwatch.put_metric_data(
                    Namespace=CLOUDWATCH_NAMESPACE,
                    MetricData=[
                        {
                            'MetricName': metric_name,
                            'Value': float(value),
                            'Unit': 'None',
                            'Timestamp': datetime.utcnow(),
                            'Dimensions': [
                                {
                                    'Name': 'MikrotikIP',
                                    'Value': ROUTER_IP
                                }
                            ]
                        }
                    ]
                )
                log(f"Successfully pushed metric {metric_name}")
            except Exception as e:
                print(f"Error pushing metric {metric_name} to CloudWatch: {str(e)}")
