/*Question 1
How many customers has Foodie-Fi ever had?*/
SELECT count(DISTINCT customer_id) AS
totalSubscribers FROM subscriptions;

/*Question 2
What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value*/
SELECT
	MONTH(start_date) AS month,
	COUNT(month(start_date)) AS total_distribution
FROM subscriptions 
GROUP BY month(start_date), plan_id 
HAVING plan_id = 0
ORDER BY month ASC

/*Question 3
What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name*/
SELECT s.plan_id, plans.plan_name, year(start_date) AS year,
COUNT(year(start_date)) 
AS eventCount FROM subscriptions AS s
JOIN plans ON s.plan_id = plans.plan_id
WHERE year(start_date)>2020
GROUP BY plans.plan_name, plan_id, year(start_date)
ORDER BY plan_id ASC

/*Question 4
What is the customer count and percentage of customers who have churned rounded to 1 decimal place?*/
SELECT plan_name,
COUNT((SELECT COUNT(DISTINCT customer_id) FROM subscriptions))
AS churnCount,
ROUND(COUNT(plans.plan_name)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1)*100
AS Percentage
FROM subscriptions AS s 
JOIN plans ON s.plan_id=plans.plan_id
WHERE plan_name = 'churn' 

/*Question 5
How many customers have churned straight after their initial free trial 
- what percentage is this rounded to the nearest whole number?*/
SELECT plan_id, COUNT(customer_id) AS customerCount,
ROUND(COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1)*100 AS pecentage
FROM subscriptions WHERE plan_id=4
AND customer_id IN(SELECT customer_id FROM subscriptions WHERE plan_id = 0);

/*Question 6
What is the number and percentage of customer plans after their initial free trial?*/
WITH customerCount AS (
    SELECT 
        p.plan_name,
        COUNT(DISTINCT s.customer_id) AS customer_count
    FROM 
        subscriptions s
    JOIN 
        plans p ON s.plan_id = p.plan_id
    WHERE 
        s.start_date <= '2020-12-31'
    GROUP BY 
        p.plan_name
)
SELECT 
    plan_name,
    customer_count,
    ROUND((customer_count * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 2) AS percentage_of_total
FROM 
	customerCount;

/*Question 7
What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?*/
WITH next_plan AS(
	SELECT 
	  customer_id, 
	  plan_id, 
	  start_date,
	  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
	FROM subscriptions
	WHERE start_date <= '2020-12-31'
),
customer_breakdown AS (
	  SELECT 
		plan_id, 
		COUNT(DISTINCT customer_id) AS customers
	  FROM next_plan
	  WHERE 
			next_date IS NOT NULL AND (start_date < '2020-12-31' 
			  AND next_date > '2020-12-31')
			OR 
			(next_date IS NULL AND start_date < '2020-12-31')
	  GROUP BY plan_id
	)
SELECT plan_id,
	customers, 
	ROUND(100 * cast(customers as float) / (SELECT COUNT(DISTINCT customer_id) 
		FROM subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id;

/*Question 8
How many customers have upgraded to an annual plan in 2020?*/
SELECT
	COUNT(DISTINCT customer_id) AS count_of_customers
FROM subscriptions
WHERE start_date LIKE '2020%' AND plan_id = 3;

/*Question 9
How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?*/
SELECT
	COUNT(DISTINCT s.customer_id) AS customerCount
    FROM subscriptions s 
    INNER JOIN plans p ON
    s.plan_id = p.plan_id
    WHERE p.plan_name = "pro annual" AND year(s.start_date) = 2020;
    
/*Question 10
Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)*/
WITH annual_plan_customers AS (
    SELECT 
        s.customer_id,
        MIN(s.start_date) AS join_date,
        MIN(CASE WHEN p.plan_name = 'pro annual' THEN s.start_date END) AS annual_plan_date
    FROM 
        subscriptions s
    JOIN 
        plans p ON s.plan_id = p.plan_id
    GROUP BY 
        s.customer_id
)
SELECT 
    CASE 
        WHEN DATEDIFF(annual_plan_date, join_date) BETWEEN 0 AND 30 THEN '0-30 days'
        WHEN DATEDIFF(annual_plan_date, join_date) BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN DATEDIFF(annual_plan_date, join_date) BETWEEN 61 AND 90 THEN '61-90 days'
        ELSE '> 90 days'
    END AS period,
    COUNT(*) AS num_customers,
    ROUND(AVG(DATEDIFF(annual_plan_date, join_date)), 2) AS average_days_to_upgrade
FROM 
    annual_plan_customers
WHERE 
    annual_plan_date IS NOT NULL
GROUP BY 
    period
ORDER BY 
    MIN(DATEDIFF(annual_plan_date, join_date));

 
/*Question 11
 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?*/
 SELECT plan_id, COUNT(DISTINCT customer_id) AS downgraded
 FROM subscriptions
 WHERE plan_id=1
 AND customer_id IN 
 (SELECT DISTINCT customer_id FROM subscriptions WHERE plan_id=2 AND YEAR(start_date) =2020);
 
