import boto3
import os
import argparse

def initiate_rds(region):
    try:
        rds_client = boto3.client('rds', region_name=region)
        return rds_client
    except Exception as e:
        print(f"Failed to authenticate to aws ssm! error: {e}")
        os._exit(0)

def create_snapshot(rds_client, source_db_instance_identifier, snapshot_identifier):
    try:
        response = rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_identifier,
            DBInstanceIdentifier=source_db_instance_identifier
        )
        print(f"Snapshot created: {response['DBSnapshot']['DBSnapshotIdentifier']}")
    except Exception as e:
        print(f"Error creating snapshot: {e}")

    # Wait for snapshot to become available
    waiter = rds_client.get_waiter('db_snapshot_available')
    waiter.wait(DBSnapshotIdentifier=snapshot_identifier)

def restore_snapshot(rds_client, new_db_instance_identifier, snapshot_identifier):
    try:
        response = rds_client.restore_db_instance_from_db_snapshot(
            DBInstanceIdentifier=new_db_instance_identifier,
            DBSnapshotIdentifier=snapshot_identifier
        )
        print(f"New DB instance created: {response['DBInstance']['DBInstanceIdentifier']}")
    except Exception as e:
        print(f"Error restoring from snapshot: {e}")

    # Wait for DB instance to become available
    waiter = rds_client.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier=new_db_instance_identifier)

if _name_ == '_main_':
    parser = argparse.ArgumentParser(description='Accept secret path')
    parser.add_argument('-e', '--environment',  required=True, help='Environment name')
    parser.add_argument('-r', '--region', default='eu-west-1', help='Region name, default is eu-west-1')
    parser.add_argument('-c', '--color',  required=True, help='Source color to migrate')
    parser.add_argument('--customer', default='shield', help='Source color to migrate')
    args=parser.parse_args()
    # Constants (replace with your values)
    source_db_instance_identifier = f"{args.environment}-{args.color}-mysql"
    destination = "blue" if args.color == "green" else "green"
    new_db_instance_identifier = f"{args.environment}-{destination}-mysql"
    snapshot_identifier = f"{source_db_instance_identifier}-snapshot"
    client = initiate_rds(args.region)
    create_snapshot(client, source_db_instance_identifier, snapshot_identifier)