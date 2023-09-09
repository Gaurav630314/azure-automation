from azure.core.credentials import AzureNamedKeyCredential
from azure.data.tables import TableServiceClient
import datetime
import re


strgacont="rgpopprodbevmdcauediag"
satoken="waF2OILVhbJRRvggJkAtboFuKRN3H6aFq+XXzNP2x5esmYzOLQtY5oIBz9Ya4HxokA+8Ge9XGqtyJGKhOUjX6Q=="

credential = AzureNamedKeyCredential(strgacont, satoken)
service = TableServiceClient(endpoint=f"https://{strgacont}.table.core.windows.net", credential=credential)

# List to store table names
table_names = []
date_format_matches = []
date_pattern = r'\d{8}'
tables = service.list_tables()
matching_tables = []
non_matching_tables = []

###########################################################################
current_date = datetime.datetime.now()
dates_last_60_days = []
# Calculate and append dates for the last 60 days
for i in range(60):
    date = current_date - datetime.timedelta(days=i)
    date_str = date.strftime('%Y%m%d')
    dates_last_60_days.append(date_str)
# Print the list of dates
print(dates_last_60_days)
###########################################################################\

# Iterate through the tables and add their names to the list
for table in tables:
    table_names.append(table.name)
#print(table_names)

for table_name in table_names:
    if re.search(date_pattern, table_name):
        date_format_matches.append(table_name)
#print(date_format_matches)


for t_name in date_format_matches:
    # Extract date part from the table name
    table_date = t_name[-8:]
    if table_date in dates_last_60_days:
        # If date matches, add the table name to matching_tables
        matching_tables.append(t_name)
    else:
        non_matching_tables.append(t_name)

print("Matching Tables:", matching_tables)

print("Non-Matching Tables:", non_matching_tables)

###############################################################
for table_name_to_delete in non_matching_tables:
    # Get a reference to the table
    table_client = service.get_table_client(table_name_to_delete)

    # Delete the table
    #table_client.delete_table()      ###Alll script tested only this line is not tested
    print(f"Deleted table: {table_name_to_delete}")

print("All tables deleted.")
