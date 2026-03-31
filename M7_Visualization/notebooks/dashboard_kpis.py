# notebooks/dashboard_kpis.py  (o .ipynb)
import duckdb, plotly.express as px

con = duckdb.connect('/shared/duckdb/capstone.duckdb', read_only=True)

df = con.execute("""
    SELECT category, 
           COUNT(*) as tickets,
           ROUND(AVG(satisfaction_score),2) as avg_satisfaction,
           ROUND(AVG(price_usd),2) as avg_price
    FROM capstone_bi_gold.fact_sales_support
    GROUP BY category ORDER BY tickets DESC
""").df()

fig = px.bar(df, x='category', y='tickets', color='avg_satisfaction',
             title='Tickets by Category — Avg Satisfaction')
fig.write_image("docs/images/dashboard_tickets.png")  # pip install kaleido