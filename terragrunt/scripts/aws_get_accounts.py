import boto3
import pandas as pd

# Initialize a boto3 client
client = boto3.client("organizations")


# Function to list all AWS accounts
def list_aws_accounts():
    accounts = []
    paginator = client.get_paginator("list_accounts")
    for page in paginator.paginate():
        for account in page["Accounts"]:
            accounts.append(
                {
                    "Id": account["Id"],
                    "Name": account["Name"],
                    "Email": account["Email"],
                    "Status": account["Status"],
                }
            )
    return accounts


# Use the function and create a DataFrame
accounts_data = list_aws_accounts()
df = pd.DataFrame(accounts_data)

# Export the DataFrame to an Excel file
excel_file = "AWS_Accounts.xlsx"
df.to_excel(excel_file, index=False)

print(f"Exported to {excel_file}")
