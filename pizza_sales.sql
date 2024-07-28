-- Q1. Retrieve the total number of orders placed.

SELECT COUNT(order_id) FROM orders AS total_orders

-- Q2. Calculate the total revenue generated from pizza sales.

SELECT SUM(p.price * od.quantity) AS total_revenue
FROM
pizzas AS p
JOIN order_details AS od
ON p.pizza_id = od.pizza_id

-- Q.3 Identify the highest-priced pizza

SELECT  pt.name, p.price 
FROM
pizza_type AS pt
JOIN pizzas as P
ON pt.pizza_type_id = p.pizza_type_id
WHERE price = (SELECT MAX(price)
			FROM pizzas)

-- Q.4 Identify the most common pizza size ordered.

SELECT p.size, COUNT(od.order_details_id) AS order_count
FROM pizzas AS P
JOIN order_details AS od
ON p.pizza_id = od.pizza_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- Q.5 List the top 5 most ordered pizza types along with their quantities.

SELECT pt.name AS pizza_type, SUM(od.quantity) AS order_count
FROM
order_details AS od
JOIN pizzas AS p 
	ON od.pizza_id = p.pizza_id
JOIN pizza_type AS pt
	ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- Q.6 Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pt.category AS pizza_type, SUM(od.quantity) AS order_count
FROM
order_details AS od
JOIN pizzas AS p 
	ON od.pizza_id = p.pizza_id
JOIN pizza_type AS pt
	ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC

-- Q.7 Determine the distribution of orders by hour of the day.

SELECT EXTRACT(HOUR FROM time) AS hour,
	COUNT(order_id) AS order_count
FROM orders
GROUP BY 1
ORDER BY 2 DESC

-- Q.8 Join relevant tables to find the category-wise distribution of pizzas.

SELECT category, COUNT(name) AS no_of_pizzas
FROM pizza_type
GROUP BY 1

-- Q.9 Group the orders by date and calculate the average number of pizzas ordered per day.

WITH temp AS(
	SELECT orders.date, SUM(order_details.quantity) AS pizza_count
	FROM orders
	JOIN order_details
	ON orders.order_id = order_details.order_id
	GROUP BY 1
	)
SELECT ROUND(AVG(pizza_count), 0) AS avg_pizza_order_per_day
	FROM temp

--Q.10 Determine the top 3 most ordered pizza types based on revenue.

SELECT pt.name, COUNT(od.quantity) AS quantity , SUM(od.quantity * p.price) AS revenue
FROM pizza_type  AS pt
JOIN pizzas AS p
	ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details AS od
	ON p.pizza_id = od.pizza_id
GROUP BY 1
ORDER BY 3 DESC
LIMIT 3

-- Q.11 Calculate the percentage contribution of each pizza type to total revenue.

WITH temp AS(
				SELECT SUM(p.price * od.quantity) AS total_revenue
				FROM
				pizzas AS p
				JOIN order_details AS od
				ON p.pizza_id = od.pizza_id
            ),

temp2 AS (
				SELECT pt.category AS category, SUM(od.quantity * p.price) / (SELECT total_revenue FROM temp) * 100 AS percentage_contribution     
				FROM pizza_type  AS pt
				JOIN pizzas AS p
					ON pt.pizza_type_id = p.pizza_type_id
				JOIN order_details AS od
					ON p.pizza_id = od.pizza_id
				GROUP BY 1
				ORDER BY 2 DESC
		)
	
SELECT category, CONCAT(ROUND(percentage_contribution:: numeric, 2), '%') 
FROM temp2

-- Q.12 Analyze the cumulative revenue generated over time.

WITH temp AS (
			SELECT o.date AS order_date, SUM(od.quantity * p.price) AS revenue  
			FROM order_details AS od 
			JOIN pizzas AS p
				ON od.pizza_id = p.pizza_id
			JOIN orders AS o
				ON o.order_id = od.order_id
			GROUP BY 1
			)

SELECT order_date, SUM(revenue) OVER(ORDER BY order_date) AS cum_revenue
FROM temp


-- Q.13 Determine the top 3 most ordered pizza types based on revenue for each pizza category.

	
SELECT category, name, revenue FROM
	(SELECT category, name , revenue,
		RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rank
		FROM 
			(SELECT pt.category AS category, pt.name AS name, SUM(od.quantity * p.price) AS revenue
			FROM pizza_type AS pt
			JOIN pizzas AS p
			ON pt.pizza_type_id = p.pizza_type_id
			JOIN order_details AS od
			ON od.pizza_id = p.pizza_id
			GROUP BY pt.category, pt.name) AS a) AS b
			WHERE rank <= 3