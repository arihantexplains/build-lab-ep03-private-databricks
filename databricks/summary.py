# Databricks notebook source
# Demo notebook for the Architect's Build Lab Episode 3 (private Databricks).
# Imported to /Shared/ab-demo/summary while public network access is still ON.
# The Dataverse plug-in submits it with runs/submit and reads the JSON it returns.

import json

dbutils.widgets.text("rows", "1000")
rows = int(dbutils.widgets.get("rows"))

# Small synthetic data so the demo needs no storage access and no extra permissions.
df = spark.range(rows).selectExpr("id", "id % 5 AS bucket", "rand(42) * 100 AS amount")
summary = (
    df.groupBy("bucket")
      .agg({"amount": "avg", "id": "count"})
      .withColumnRenamed("avg(amount)", "avg_amount")
      .withColumnRenamed("count(id)", "row_count")
      .orderBy("bucket")
)

result = {
    "rows": rows,
    "buckets": [
        {"bucket": r["bucket"], "rowCount": r["row_count"], "avgAmount": round(r["avg_amount"], 2)}
        for r in summary.collect()
    ],
    "sparkVersion": spark.version,
}

dbutils.notebook.exit(json.dumps(result))
