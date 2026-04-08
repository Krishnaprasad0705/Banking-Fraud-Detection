import json,sys
p=r'd:\MCP\BankMCP.ipynb'
with open(p,'r',encoding='utf-8') as f:
    nb=json.load(f)
# find the batch insert cell by searching for the print string
for i,cell in enumerate(nb.get('cells',[]),1):
    if cell.get('cell_type')=='code' and any('100,000 transactions inserted successfully' in s for s in cell.get('source',[])):
        src='\n'.join(cell.get('source',[]))
        break
else:
    print('Batch insert cell not found')
    sys.exit(1)
# execute the cell
print('Executing batch insert cell...')
exec_globals={}
# provide conn and cursor by importing from notebook first cell context
# assume connection is available by importing module: reuse pyodbc connect here
import pyodbc
conn = pyodbc.connect("DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost\\SQLEXPRESS;DATABASE=banking_db;Trusted_Connection=yes;")
cursor = conn.cursor()
exec_globals['conn']=conn
exec_globals['cursor']=cursor
try:
    exec(src, exec_globals)
    print('Batch insert executed')
except Exception as e:
    import traceback
    traceback.print_exc()
    sys.exit(2)
