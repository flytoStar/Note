select score,
     dense_rank() over(order by score desc) ranking
 from Score;


select distinct salary as secondhighsalary
from empolyee
order by salary desc
limit 1 offset 1;


select s1.salary
from 
(select salary ,
rank() over(order by salary desc) ranking
from employee
group by salary ) s1
where s1.ranking = n;
select s1.num
from 
(select num,
lead(num,1,null) over(order by id) l1
lead(num,2,null) over（order by id）l2
from logs) s1
where num = s1.l1 and num = s1.l2;


select e.name,e.salary
from employee e
join manager m
on managerid = id 
where e.salary > m.salary ;
