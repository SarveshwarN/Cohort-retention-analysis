# Cohort-retention-analysis

Executive Summary

This project analyzes customer retention behavior using cohort analysis on a real-world e-commerce dataset.
The objective is to understand how long customers stay active after their first purchase, identify key churn points, and evaluate long-term customer value.

Using Microsoft Fabric (SQL + Semantic Model) and Power BI, I built an end-to-end analytics solution covering data cleaning, cohort modeling, retention metrics, and an interactive dashboard.
The analysis reveals strong early retention, high repeat purchase behavior, and a small but valuable long-term loyal user base.

Business Problem

Customer acquisition is expensive, and long-term growth depends on retaining customers beyond their first purchase.

Key business questions addressed:

How many customers return after their first purchase?

Where does the largest drop-off in retention occur?

Do retained users generate meaningful long-term value?

How does retention evolve month-by-month after acquisition?

Answering these questions helps product and growth teams prioritize onboarding improvements, lifecycle nudges, and loyalty strategies.

Methodology

Data Cleaning & Preparation

Cleaned raw order data to create a reliable order-level dataset

Handled missing customers, duplicates, and invalid dates

Derived order month and customer purchase timelines

Cohort Definition

Defined cohort_month as the customer’s first purchase month

Calculated months_since_first_order for each subsequent order

Retention Modeling (SQL-First)

Built a long-format retention table for flexible analysis

Created a wide retention matrix (Month-0 to Month-12) for heatmap visualization

Calculated cohort size, retained customers, and retention percentage

Advanced Metrics

Repeat purchase rate

Lifetime orders per customer (LTV proxy)

Orders per active customer over time

Visualization

Designed an interactive Power BI dashboard using a Fabric Semantic Model

Included KPIs, cohort heatmap, and retention decay analysis

Skills

SQL (Microsoft Fabric Lakehouse SQL)

Cohort Analysis & Retention Modeling

Microsoft Fabric Semantic Modeling

Power BI Dashboard Development

Business & Product Analytics

Data Cleaning & Feature Engineering

Metric Design (Retention, Repeat Rate, LTV Proxies)

Results and Business Recommendations
Key Results

Month-1 Retention: 85.75% — strong early engagement

Repeat Purchase Rate: 100% — all customers reordered at least once

Lifetime Orders per Customer: ~16.6 orders

Churn Pattern: Gradual decline, not abrupt drop-offs

Long-term Loyal Base: ~10% of users remain active after 11 months

Business Recommendations

Improve post-first-order onboarding to reduce early churn

Introduce lifecycle nudges between Month-1 and Month-3

Create loyalty or subscription programs for long-term retained users

Focus growth efforts on retention optimization, not just acquisition

Next Steps

Segment cohorts by product category, order frequency, or geography

Add revenue-based metrics if pricing data is available

Perform A/B test analysis on retention improvement initiatives

Build predictive models to identify high-risk churn users
