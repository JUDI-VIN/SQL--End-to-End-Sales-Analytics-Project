create database sql_project;

use project;

select count(id) as 'total_product' from product;

select count(id) as 'total_customers' from customers;

--- max, min, avg order
select 
min(total_orders) as min_order, 
max(total_orders) as max_order,
avg(total_orders) as avg_order
from (
select sum(price * item_quantity) as total_orders
from order_item 
group by order_id) as a


----  max, min, avg order in terms of money
    
select
cast(min(total_orders) as money) as min_order,
cast(max(total_orders) as money) as max_order,
cast(avg(total_orders) as money) as avg_order
from (
select sum(price * item_quantity) as total_orders
from order_item
group by order_id) as a


-- Orders trend over the week
select
datepart (week, created_at) as 'week',
count(*) as 'orders'
from orders
group by datepart (week, created_at)
order by orders desc;

-- count number of the orders for each customer
select
CONCAT(first_name, ' ', last_name) as full_name,
city,
count(o.id) as total_orders
from customers c
inner join orders o on c.id = o.customer_id
group by CONCAT(first_name, ' ', last_name), city
order by total_orders desc

--- ALTERNATE METHOD
SELECT c.first_name,
count(c.id) as total_orders
FROM customers c
JOIN orders ON customer_id = c.id
GROUP BY c.first_name
order by total_orders desc


----  find customers with reference (self join coz 2 info from same table)
select
c.id,
CONCAT(c.first_name, ' ', c.last_name) as customer_name,
CONCAT(r.first_name, ' ', r.last_name) as referred_name
from customers c
inner join customers r on c.referral_customer_id = cast(r.id as nvarchar(50))---null is not converted to integer so cast is used
where c.referral_customer_id is not null;

-- count number of referred customers per referee
with max_refer as (
select
c.id, 
CONCAT(c.first_name, ' ', c.last_name) as customer_name,
CONCAT(r.first_name, ' ', r.last_name) as referred_name
from customers c
inner join customers r on c.referral_customer_id = cast(r.id as nvarchar(50))
where c.referral_customer_id is not null
)
select referred_name,
count(id) as referred_count
from max_refer
group by referred_name
order by referred_count desc;

------top 5 popular products
select top 5 name as 'name',
sum(item_quantity) as product_count
from product p 
inner join order_item o
on p.id = o.product_id
group by name
order by product_count desc

--- top 5 products in terms of revenue
select top 5 name as 'name',
sum(o.price * item_quantity) as total_revenue
from product p
inner join order_item o
on p.id = o.product_id
group by name
order by total_revenue desc;

--- analysis over rating score
select
case 
when rating = 5 then 'Excellent'
when rating = 4 then 'Good'
when rating = 3 then 'Satisfied'
when rating = 2 then 'Bad'
when rating in (1,0) then 'Terrible'
end as sentiment_analysis,
count(*) as rating_count,    ------- VARCHAR IS USED TO CONCATE % SYMBOL
cast(round(count(*) * 100 / (select count(*) from orders), 2) as varchar(20)) + '%' as percent_dist
from orders
group by 
case 
when rating = 5 then 'Excellent'
when rating = 4 then 'Good'
when rating = 3 then 'Satisfied'
when rating = 2 then 'Bad'
when rating in (1,0) then 'Terrible'
end

--- ALT METHOD FOR BELOW RANK FUNCTION
with raw_data as (
select p.name as product_name ,sum(oi.item_quantity) as items_sold, sum(oi.item_quantity * oi.price)as revenue 
from product as p
inner join order_items as oi on oi.product_id = p.id
group by product_name
)
select product_name,
dense_rank() over (order by items_sold desc) as sale_rank ,
dense_rank() over (order by revenue desc) as revenue_rank from raw_data;


----use rank function to find the top 10 sales in terms of product count and revenue
with top_product as (
select top 10 p.id,
name,
sum(o.item_quantity) as product_count
from product p
inner join order_item o 
on p.id = o.product_id
group by p.id, name
), 
revenue as (
select top 10 p.id,
name,
sum(o.price * o.item_quantity) as revenue
from product p
inner join order_item o
on p.id = o.product_id
group by p.id, name
)
select r.name,
product_count,
revenue,
DENSE_RANK() over (order by product_count desc) as product_rank,
DENSE_RANK() over (order by revenue desc) as revenue_rank
from top_product t
inner join revenue r on t.id = r.id

--- top 3 customers wigh highest tips
select  top 3 c.first_name, c.last_name,
sum(o.tips) as sum_tips
from customers c
inner join orders o on c.id = o.customer_id
group by c.first_name, c.last_name
order by sum_tips desc






