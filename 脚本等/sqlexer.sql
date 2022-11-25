select
	employee_id,
	last_name,
	department_id,
	salary
from
	employees
where
	department_id=(select department_id from employees where first_name="Zlotkey" or last_name="Zlotkey");


	select
		employee_id,
		first_name,
		last_name,
		salary
	from
		employees
	where
		salary>(select avg(salary) from employees);

select
	employee_id,
	first_name,
	last_name,
	department_id,
	salary
from
	employees
where
	salary>(select avg(salary) from employees )
group by 
	department_id;

select
	employee_id,
	first_name,
	last_name
from
	employees
where
	count(select from employees where first_name like '%u%'
or
	last_name like '%u%'
group by
	department_id;

select
	employee_id,
	department_id
from
	employees
where
	location_id in(select from locations where location_id=1700);
