1.What is the total amount each customer spent at the restaurant?
select customer_id, concat('Rs.', sum(price))
from d.sales s
join d.menu m
on s.product_id = m.product_id 
group by customer_id
order by customer_id 

2.How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as no_of_visits
from d.sales 
group by customer_id
order by customer_id

3.What was the first item from the menu purchased by each customer?
select customer_id, t1.product_id, product_name
from
    (select *, dense_rank() over (partition by customer_id
                                 order by order_date) as ranking
    from d.sales) t1
join d.menu m 
on t1.product_id = m.product_id
where ranking = 1 
order by customer_id

4.What is the most purchased item on the menu and how many times was it purchased by all customers?
select s.product_id, product_name, count(s.product_id)
from d.sales s
join d.menu m
on s.product_id = m.product_id
group by s.product_id, product_name

5.Which item was the most popular for each customer?
select *
from 
    (select *, dense_rank() over(partition by customer_id 
                                order by popular desc) as ranking 
    from                            
        (select customer_id, s.product_id, product_name, count(s.product_id) as popular
        from d.sales s
        join d.menu m
        on s.product_id = m.product_id
        group by customer_id, s.product_id, product_name
        ) t1) t2
where ranking = 1 

6.Which item was purchased first by the customer after they became a member?
select t1.customer_id, first_order, s.product_id, product_name 
from
    (select s.customer_id, min(order_date) as first_order
    from d.sales s 
    join d.members m
    on s.customer_id = m.customer_id 
    where order_date >= join_date
    group by s.customer_id) t1 
join d.sales s 
on s.customer_id = t1.customer_id and s.order_date = t1.first_order
join d.menu me
on s.product_id = me.product_id

7.Which item was purchased just before the customer became a member?
select t1.customer_id, first_order, s.product_id, product_name 
from
	(select s.customer_id, max(order_date) as first_order
    from d.sales s 
    join d.members m
    on s.customer_id = m.customer_id 
    where order_date < join_date
    group by s.customer_id) t1 
join d.sales s 
on s.customer_id = t1.customer_id and s.order_date = t1.first_order
join d.menu me
on s.product_id = me.product_id

8.What is the total items and amount spent for each member before they became a member?
	  select s.customer_id, count(s.product_id) as no_of_items, 				sum(price) as tot_price
    from d.sales s 
    join d.members m
    on s.customer_id = m.customer_id 
    join d.menu me 
    on s.product_id = me.product_id
    where order_date < join_date
    group by s.customer_id
    
 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
 select customer_id, sum(price_cal) as points_earned
from
      (select customer_id, product_name, sum(price),
              (case when product_name = 'sushi' then sum(price)*20
                   else sum(price)*10 end ) as price_cal
      from d.sales s
      join d.menu m
      on s.product_id = m.product_id 
      group by customer_id, product_name
      order by customer_id, product_name) t1
group by customer_id 

10.n the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id, sum(price_categ) as points
from
      (select s.customer_id, order_date, join_date, product_name, price,
             (case when product_name = 'sushi' then price*20
                  else (case when order_date < join_date then price*10 
                              when order_date between join_date and join_date+6 then price*20
                        end)
             end) as price_categ                 
      from d.sales s 
      join d.menu m 
      on s.product_id = m.product_id
      join d.members mem
      on s.customer_id = mem.customer_id
      order by customer_id, order_date) t1
group by customer_id  

BONUS QUESTIONS TO JOIN ALL 
(select s.customer_id, order_date, product_name, price,
		(case when order_date < join_date then 'N'
        	 else 'Y' end) as Members
from d.sales s 
join d.menu m 
on s.product_id = m.product_id
join d.members mem
on s.customer_id = mem.customer_id
order by customer_id, order_date)
UNION ALL
(select s.customer_id, order_date, product_name, price, 'N' as Members
from d.sales s 
join d.menu m 
on s.product_id = m.product_id
where s.customer_id not IN (select distinct customer_id from d.members))

(OR) - This is without UNION and using LEFT JOIN

select s.customer_id, order_date, join_date, product_name, price,
		(case when order_date < join_date or join_date is null then 'N'
        	 else 'Y' end) as Members
from d.sales s 
join d.menu m 
on s.product_id = m.product_id
left join d.members mem
on s.customer_id = mem.customer_id
order by customer_id, order_date

RANKING FOR MEMBERS ONLY 
select * 
from
          ((select *, rank() over(partition by customer_id 
                                order by order_date) as Ranking
          from 
                    ((select s.customer_id, order_date, product_name, price,
                            (case when order_date < join_date then 'N'
                                 else 'Y' end) as Members
                    from d.sales s 
                    join d.menu m 
                    on s.product_id = m.product_id
                    join d.members mem
                    on s.customer_id = mem.customer_id
                    order by customer_id, order_date)
                    UNION ALL
                    (select s.customer_id, order_date, product_name, price, 'N' as Members
                    from d.sales s 
                    join d.menu m 
                    on s.product_id = m.product_id
                    where s.customer_id not IN (select distinct customer_id from d.members))) b1
          where Members = 'Y' )  
          UNION ALL 
          (select *, null
           from 
                    ((select s.customer_id, order_date, product_name, price,
                            (case when order_date < join_date then 'N'
                                 else 'Y' end) as Members
                    from d.sales s 
                    join d.menu m 
                    on s.product_id = m.product_id
                    join d.members mem
                    on s.customer_id = mem.customer_id
                    order by customer_id, order_date)
                    UNION ALL
                    (select s.customer_id, order_date, product_name, price, 'N' as Members
                    from d.sales s 
                    join d.menu m 
                    on s.product_id = m.product_id
                    where s.customer_id not IN (select distinct customer_id from d.members))) b1
          where Members = 'N')) b2 
order by customer_id, order_date 

(OR) Without UNION and using LEFT JOIN

select *, (case when members = 'Y' then rank() over(partition by customer_id, members 
                      								order by order_date)
               else null end) as Ranking                                
from                     
      (select s.customer_id, order_date, join_date, product_name, price,
              (case when order_date < join_date or join_date is null then 'N'
                   else 'Y' end) as Members
      from d.sales s 
      join d.menu m 
      on s.product_id = m.product_id
      left join d.members mem
      on s.customer_id = mem.customer_id)t1
order by customer_id 