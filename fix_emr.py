path = r'C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\emr\index.html'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the corrupted Submitted Forms line that has a literal backslash-n prefix
old_sub = '    \\n    ${sectionCard(\'\U0001f4c4 Submitted Forms\''
new_sub = '    ${sectionCard(\'\U0001f4c4 Submitted Forms\''
if old_sub in content:
    content = content.replace(old_sub, new_sub, 1)
    print('Fixed Submitted Forms line')
else:
    idx = content.find('Submitted Forms')
    print('Submitted Forms pattern not found, context:', repr(content[idx-30:idx+80]))

# Insert Med Log section after Sign In/Out, before Application
med_log_line = '    ${sectionCard(\'\U0001f48a Medication Log\', medLogs, renderMedLog(medLogs))}\n'
insert_after = '    ${sectionCard(\'\U0001f6aa Sign In / Out Records\', signInOutRecords, renderSignInOut(signInOutRecords))}\n'

if med_log_line in content:
    print('Med Log line already present')
elif insert_after in content:
    content = content.replace(insert_after, insert_after + med_log_line, 1)
    print('Inserted Med Log section')
else:
    print('Sign In/Out anchor not found')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i, l in enumerate(lines[502:517], 503):
    print(i, repr(l))
