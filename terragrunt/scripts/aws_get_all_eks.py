import boto3
import pandas as pd
from termcolor import colored


def get_all_eks_regions():
    """
    Get all AWS regions that support EKS service.
    """
    ec2_client = boto3.client("ec2")
    regions = [
        region["RegionName"] for region in ec2_client.describe_regions()["Regions"]
    ]
    eks_regions = []
    for region in regions:
        try:
            # Check if EKS is available in the region by attempting to create a client
            boto3.client("eks", region_name=region)
            eks_regions.append(region)
        except Exception as e:
            print(f"EKS is not available in {region}: {e}")
    return eks_regions


def list_eks_clusters(credentials, regions):
    """
    Lists EKS clusters in all specified regions using given credentials.
    """
    clusters_info = []
    for region in regions:
        eks_client = boto3.client(
            "eks",
            region_name=region,
            aws_access_key_id=credentials["AccessKeyId"],
            aws_secret_access_key=credentials["SecretAccessKey"],
            aws_session_token=credentials["SessionToken"],
        )
        try:
            clusters = eks_client.list_clusters()["clusters"]
            for cluster in clusters:
                clusters_info.append({"Region": region, "Cluster": cluster})
        except Exception as e:
            print(f"Failed to list clusters in {region}: {e}")

    return clusters_info


# The rest of your functions remain unchanged...


def main():
    role_name = "AWSAFTExecution"  # Role name to assume in each account
    all_accounts = list_aws_accounts()
    all_regions = get_all_eks_regions()
    account_clusters = []  # To hold account and cluster info

    for account in all_accounts:
        account_id = account["Id"]
        try:
            credentials = assume_role(account_id, role_name)
            clusters = list_eks_clusters(credentials, all_regions)
            if clusters:
                for cluster_info in clusters:
                    account_clusters.append(
                        {
                            "Account ID": account_id,
                            "Account Name": account["Name"],
                            **cluster_info,
                        }
                    )
                print(
                    colored(
                        f"Found EKS Clusters in account {account_id} ({account['Name']}): {clusters}",
                        "green",
                    )
                )
            else:
                account_clusters.append(
                    {
                        "Account ID": account_id,
                        "Account Name": account["Name"],
                        "Region": "N/A",
                        "Cluster": "No Clusters Found",
                    }
                )
                print(
                    f"No EKS Clusters found in account {account_id} ({account['Name']})."
                )
        except Exception as e:
            print(f"Error in account {account_id} ({account['Name']}): {e}")
            account_clusters.append(
                {
                    "Account ID": account_id,
                    "Account Name": account["Name"],
                    "Region": "N/A",
                    "Cluster": f"Error: {e}",
                }
            )

    write_to_excel(account_clusters)


if __name__ == "_main_":
    main()
