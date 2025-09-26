import json
import pandas as pd

# Загрузка JSON
with open('risks.json', 'r', encoding='utf-8') as f:
    risks = json.load(f)

# Преобразование в DataFrame
df = pd.json_normalize(risks)

# Выбор нужных колонок
df = df[[
    'severity',
    'category',
    'most_relevant_technical_asset',
    'exploitation_likelihood',
    'exploitation_impact',
    'title'
]]

# Переименование колонок
df.columns = ['Severity', 'Category', 'Asset', 'Likelihood', 'Impact', 'Title']

# Сохранение в Excel
df.to_excel('risks.xlsx', index=False)
print("risks.xlsx создан!")
