/*This is a SQL Zomato data exploration project*/
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date);
INSERT INTO goldusers_signup(userid,gold_signup_date) VALUES (1,'2017-09-22'),(3,'2017-04-21');
drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 
INSERT INTO users(userid,signup_date) VALUES (1,'2014-09-02'),(2,'2015-01-15'),(3,'2014-04-11');
drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 
INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);
drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 
INSERT INTO product(product_id,product_name,price) VALUES(1,'p1',980),(2,'p2',870),(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

#What is the total amount each customer spent on zomato
SELECT one.userid,sum(two.price) as total_price FROM sales AS one INNER JOIN product AS two ON one.product_id = two.product_id
group by userid;

#How many days/times  each customer visited zomato
select userid, count(distinct created_date) number_of_visits from sales group by userid;

#what was the first product by each customer, to understand which is the most likey product brought by new customers
select *, rank() over(partition by userid order by created_date) rnk from sales;

#what is the most purchased item on the menu & how many times was it purch(Type 1)
select product_id, count(product_id) from sales group by product_id order by count(product_id) desc;

#what is the most purchased item on the menu & how many times was it purch(Type 2)
select product_id, count(product_id) from sales group by product_id order by count(product_id) desc limit 1;

# which item was most popular for each customer
select *, rank() over(partition by userid order by cnt desc) rnk from
(select userid, product_id, count(product_id) as cnt from sales group by userid, product_id) as d;

#which item was first purchased by the customer after they become gold member
select c.*, rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date>=gold_signup_date) as c;

#which item was purchased by the customer just before they become gold member(type 1)
select c.*, rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date<=gold_signup_date) as c;

#which item was purchased by the customer just before they become gold member(type 2)
Select * from
(select c.*, rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date<=gold_signup_date) as c) as d where rnk=1;

#what is the total order and amount spent by each cust before they become gold member(step 1)
select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date<=gold_signup_date;

#what is the total order and amount spent by each cust before they become gold member(step 2)
select c.*, d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date<=gold_signup_date) as c INNER JOIN 
product AS d ON c.product_id=d.product_id;

#what is the total order and total amount spent by each cust before they become gold member(step 3)
select userid,count(created_date) as total_order,sum(price) as total_amount from
(select c.*, d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date<=gold_signup_date) as c INNER JOIN 
product AS d ON c.product_id=d.product_id) as e group by userid;

/*If each product has been assigned purchase points and each product has diffrent purchase points 
eg: P1= 5Rs = 1 points, P2= 10Rs = 2 points, P3= 5Rs = 1 points
calculate total points collected by each customer and for which product most points have been given(step 1)*/
select * from sales;
select * from product;

select c.userid,c.product_id,sum(price) from
(select a.*,b.price from sales AS a INNER JOIN product AS b ON a.product_id=b.product_id) AS c
group by userid,product_id order by userid;

#calculate total points collected by each customer and for which product most points have been given(step 2)
select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end AS points from
(select c.userid,c.product_id,sum(price) AS amt from
(select a.*,b.price from sales AS a INNER JOIN product AS b ON a.product_id=b.product_id) AS c
group by userid,product_id order by userid) AS d;

#calculate total points collected by each customer and for which product most points have been given(step 3)
select e.*,round(amt/points,0) AS total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end AS points from
(select c.userid,c.product_id,sum(price) AS amt from
(select a.*,b.price from sales AS a INNER JOIN product AS b ON a.product_id=b.product_id) AS c
group by userid,product_id order by userid) AS d) AS e;

#calculate total points collected by each customer and for which product most points have been given(step 4)
select userid,sum(total_points) from
(select e.*,round(amt/points,0) AS total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end AS points from
(select c.userid,c.product_id,sum(price) AS amt from
(select a.*,b.price from sales AS a INNER JOIN product AS b ON a.product_id=b.product_id) AS c
group by userid,product_id order by userid) AS d) AS e) AS f group by userid;

#calculate total points collected by each customer and for which product most points have been given(step 5)
select userid,sum(total_points)*2.5 AS total_money from
(select e.*,round(amt/points,0) AS total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end AS points from
(select c.userid,c.product_id,sum(price) AS amt from
(select a.*,b.price from sales AS a INNER JOIN product AS b ON a.product_id=b.product_id) AS c
group by userid,product_id order by userid) AS d) AS e) AS f group by userid;

/*in the first one year after the customer joins the gold memebership(inculding the joining date) irrespective 
of what the customer has purchased they get 5 points for every Rs. 10 spent, who earned more 1 or 3 and 
what was their points earning in first year*/
#(step 1) this will give gold_signup_date upto 1 year
select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date>=gold_signup_date and 
created_date<=DATE_ADD(gold_signup_date, interval 1 year)


#1 point = Rs2, so 0.5 points = Rs 1(step 2)
select c.*,d.price*0.5 AS total_points from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales AS a INNER JOIN 
goldusers_signup AS b ON a.userid=b.userid and created_date>=gold_signup_date and 
created_date<=DATE_ADD(gold_signup_date, interval 1 year)) AS c
INNER JOIN product d ON c.product_id=d.product_id;

/*Rank all transtions of each customer*/
select * from sales;
select *, rank() over(partition by userid order by created_date) rnk from sales;