import json
with open("labs/lab2/risks.json","r") as f:
    data = json.load(f)

# Severity: critical=5, elevated=4, high=3, medium=2, low=1
# Likelihood: very-likely=4, likely=3, possible=2, unlikely=1
# Impact: high=3, medium=2, low=1
result = []

severity = {"critical":5, "elevated":4, "high":3, "medium":2, "low":1}
likelihood = {"very-likely":4, "likely":3, "possible":2, "unlikely":1}
impact = {"high":3, "medium":2, "low":1}
for risk in data:
    result.append({"category":risk["category"], "severity":severity[risk["severity"]],"asset":risk["most_relevant_technical_asset"],"exploitation_likelihood":likelihood[risk["exploitation_likelihood"]],"exploitation_impact":impact[risk["exploitation_impact"]], "result":0})

for risk in result:
    # Severity100 + Likelihood10 + Impact
    risk["result"] = risk["severity"] * 100 +risk["exploitation_likelihood"] *10 +risk["exploitation_impact"]
result_sorted = sorted(result, key=lambda x:(x["result"],x["severity"],x["asset"],x["exploitation_likelihood"],x["exploitation_impact"]),reverse=True)

print(result_sorted[:5])