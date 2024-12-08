import sys, json
data = json.loads(sys.stdin.read())
if data.get("estimatedProfitUSD", 0) >= 500000:
    print("true")
else:
    print("false")
