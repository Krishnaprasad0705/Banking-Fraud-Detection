import json,sys,traceback
p=r"d:\MCP\BankMCP.ipynb"
with open(p,'r',encoding='utf-8') as f:
    data=json.load(f)
errors=[]
for i,cell in enumerate(data.get('cells',[]),1):
    if cell.get('cell_type')=='code':
        src='\n'.join(cell.get('source',[]))
        try:
            compile(src,f'<cell {i}>','exec')
        except Exception as e:
            errors.append((i, e, traceback.format_exc()))
if not errors:
    print('OK: no syntax errors in code cells')
    sys.exit(0)
for i,e,t in errors:
    print(f'Cell {i} SyntaxError:', e)
    print(t)
sys.exit(2)
