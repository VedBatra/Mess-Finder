import re
with open('supabase/schema.sql', 'r') as f:
    content = f.read()

pattern = r'create policy (\".*?\")\s+on\s+(public\.[a-zA-Z0-9_]+)'

def replacer(match):
    policy_name = match.group(1)
    table_name = match.group(2)
    return f'drop policy if exists {policy_name} on {table_name};\ncreate policy {policy_name}\n  on {table_name}'

new_content = re.sub(pattern, replacer, content)

with open('supabase/schema.sql', 'w') as f:
    f.write(new_content)
