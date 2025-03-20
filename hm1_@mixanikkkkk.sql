create table users(
	id int not null primary key,
	name varchar(100) not null,
	email varchar(100) not null,
	created_at timestamp)

create table categories(
	id int primary key,
	name varchar(100))

create table products(
	id int primary key,
	name varchar(100) not null,
	price numeric(10,2) not null constraint positive_price check(price>0),
	category_id int references categories(id) on delete set null)

create table orders(
	id int primary key,
	user_id int not null references users(id),
	status varchar(50) default 'Ожидает оплаты',
	created_at timestamp)

create table order_items(
	id int primary key,
	order_id int references orders(id),
	product_id int references products(id),
	quantity int check(quantity>0))

create table payments(
	id int primary key,
	order_id int references orders(id),
	amount numeric(10, 2) constraint positive_value check(amount>0),
	payment_date timestamp default current_timestamp)

#Задача 1
select cname as category_name, round(avg(avg), 2) as avg_order_amount from
	(select avg(sum), cname from
		(select *, sum(pcoi.price) over(partition by pcoi.cname, o.id) from
			(select pc.cname, pc.pname, pc.price, oi.order_id from
				(select c.name as cname, p.price, p.name as pname , p.id from products as p inner join categories as c
				on c.id=p.category_id) as pc
			inner join order_items as oi on pc.id=oi.product_id) as pcoi
		inner join orders as o on pcoi.order_id=o.id
		where extract (month from o.created_at)=03) as en
	group by cname, id)
group by cname

#Задача 2
select name as user_name, sum(amount) as total_spent, rank() over(order by sum(amount) desc) as user_rank from
	(select u.name, o.id as order_id, o.status from users as u right join orders as o
	on o.user_id=u.id where o.status='Оплачен') as ord
left join payments as p on p.order_id=ord.order_id
group by name
limit 3

#Задача 3
select to_char(created_at, 'YYYY-MM')  as month,count(order_id) as total_orders, sum(amount) as total_payments from
	(select o.id as order_id, o.created_at, p.amount, p.payment_date from orders as o
	left join payments as p on o.id=p.order_id) as ord
group by month
order by month

#Задача 4
select name as product_name, total_sold, round((total_sold/sum*100), 2) as sales_percantage from
	(select sum(oi.quantity) as total_sold, p.name, sum(sum(oi.quantity)) over() from order_items as oi
	left join products as p on p.id=oi.product_id
	group by name) as en
limit 5

#Задача 5
select user_name, total_spent from
	(select name as user_name, sum(amount) as total_spent, avg(sum(amount)) over() from
		(select u.name, o.id as order_id, o.status from users as u right join orders as o
		on o.user_id=u.id where o.status='Оплачен') as ord
	left join payments as p on p.order_id=ord.order_id
	group by name) as en
where total_spent>avg

#Задача 6
select cname as category_name, pname as product_name, avg as total_sold from
	(select avg(sum), pname, cname, row_number() over(partition by cname order by avg(sum) desc) from
		(select sum, pr.name as pname, c.name as cname from
			(select sum(oi.quantity)over(partition by p.name), p.name, p.category_id from order_items as oi
			left join products as p on oi.product_id=p.id
			) as pr
		left join categories c on c.id=category_id) as en
	group by cname, pname
	order by cname) as al
where row_number<=3
order by category_name, row_number

#Задача 7
select to_char(created_at, 'YYYY-MM') as month, cname as category_name, sum as total_revenue from
	(SELECT cname, pname,created_at, sum, MONTH, row_number() over(partition by month order by month, sum desc ) as pos from
			(select c.name as cname,pr.name as pname, pr.created_at, sum(s) over(partition by c.name, extract(month from created_at)), extract(month from created_at) as month from
				(select p.name, p.price, p.category_id, ord.quantity, ord. created_at, p.price*ord.quantity as s from
					(select oi.product_id, oi.order_id, oi.quantity, o.created_at from order_items oi
					left join orders o
					on o.id=oi.order_id
					) ord
				left join products p
				on p.id=ord.product_id) pr
			left join categories c
			on c.id=pr.category_id
			order by month, sum desc) AS en)
	where month<=6 and pos=1

#Задача 8
select month, s as monthly_payment, sum(s)	over(rows UNBOUNDED PRECEDING) as cumulative_payments from
	(select month, sum(amount) as s from
		(select to_char(payment_date, 'YYYY-MM')as month, p.payment_date, p.amount from payments p
		where extract(month from payment_date)<>0
		order by extract(month from payment_date) )
	group by month)
