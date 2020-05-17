---------------------------------------------------------------
/* 
Springboard Data Science Career Track - March 2 Cohort
Date: 2020-05-17
By:			Justin Huang	| justin.j.huang@gmail.com
Advisor:	Blake Arensdorf | blake.arensdorf@gmail.com
*/
---------------------------------------------------------------

/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

SELECT		name
			,membercost
FROM		Facilities
WHERE		membercost = 0

/* Q2: How many facilities do not charge a fee to members? */

SELECT		COUNT(membercost) as "Qty Facilities Do Not Charge Member Fee"
FROM		Facilities
WHERE		membercost = 0
GROUP BY	membercost

/* Q3: How can you produce a list of facilities that charge a fee to members, 
where the fee is less than 20% of the facility's monthly maintenance cost? 
Return the facid, facility name, member cost, and monthly maintenance of the facilities in question. */

SELECT		facid, name, membercost, monthlymaintenance
FROM		Facilities
WHERE		(membercost <> 0)  AND	(membercost / monthlymaintenance) < 0.2


/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

SELECT	Facilities.* 
FROM	Facilities
WHERE	facid in (1, 5)

/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

SELECT	Facilities.*
		,Case
			when monthlymaintenance > 100 then 'expensive'
			else 'cheap'
		End as "CostDescription"
FROM	Facilities


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */

SELECT		firstname,surname,joindate
FROM		Members
WHERE		joindate = 
	(
		SELECT		MAX(joindate) as "LatestJoinDate"
		FROM		Members
	)


/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

/*
Filter, Group then Join
*/

WITH
TENNIS_COURT_BOOKINGS as (
	SELECT	b.facid
			,b.memid
			,1 AS BookingCount			
	FROM	Bookings b
	WHERE	b.facid in (0,1)
),
TENNIS_COURT_BOOKINGS_SUM as (
	Select	tb.facid
			, tb.memid
			, sum(tb.BookingCount) as "Bookings"
	FROM	TENNIS_COURT_BOOKINGS tb
	GROUP BY	tb.facid, tb.memid
)

SELECT		f.name as "TennisCourtName"
			, m.firstname + ' ' + m.surname as "FullName"
			, tbs.Bookings
FROM		TENNIS_COURT_BOOKINGS_SUM tbs
LEFT JOIN	Facilities f	on tbs.facid = f.facid
LEFT JOIN	Members m		on m.memid = tbs.memid
ORDER BY	tbs.Bookings DESC


/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. 

Include in your output the name of the facility, 
the name of the member formatted as a single column, and the cost.

Order by descending cost, and do not use any subqueries. */

SELECT	
		b.bookid as "BookingID"
		, f.name as "FacilityName"
		, m.firstname + ' ' + m.surname as "FullName"
		, Case
			when b.memid = 0 then format(guestcost * slots, 'C')
			else				format(membercost * slots, 'C')
		End "TotalCost"
		, Case
			when b.memid = 0 then guestcost * slots
			else				membercost * slots
		End "TotalCostSort"

FROM	Bookings b

left join Members m on b.memid = m.memid
left join Facilities f on b.facid = f.facid

where b.starttime like '2012-09-14%'
and (((guestcost * slots > 30) and (b.memid = 0)) OR ((membercost * slots > 30) and (b.memid <> 0)))

ORDER BY TotalCostSort DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */
Select A.FacilityName, A.FullName, A.TotalCost
From 
(
	Select 	b.bookid as "BookingID"
			, f.name as "FacilityName"
			, m.firstname + ' ' + m.surname as "FullName"
			, Case
				when b.memid = 0 then format(guestcost * slots, 'C')
				else				format(membercost * slots, 'C')
			End "TotalCost"
			, Case
				when b.memid = 0 then guestcost * slots
				else				membercost * slots
			End "TotalCostSort"
	From
	(
		Select Bookings.* 
		FROM	Bookings
		where	Bookings.starttime like '2012-09-14%'
	) b
	left join Members m on b.memid = m.memid
	left join Facilities f on b.facid = f.facid


	where
	(
	
		((f.guestcost * b.slots > 30) and (b.memid = 0))
		OR
		((f.membercost * b.slots > 30) and (b.memid <> 0))
	
	)
) 
A
ORDER BY TotalCostSort DESC



/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

WITH
BOOKINGS_TEMP AS
(
	SELECT	facid
			,memid
			,sum(slots) as slots_sum
			, Case
				when memid = 0 then 'Guest'
				else 'Member'
			End as MemberType
			,count(bookid) as "Qty"
  
	  FROM		Bookings
	  --WHERE		NOT(facid in (7,8) and memid <> 0) --filtering out pool/snooker tables to members as they generate 0 revenue prior to the join
	  Group by	facid, memid
)
/* not sure how to calculate that total revenue so used 2 methods:
Revenue1 = booking qty * cost
Revenue2 = slots qty * cost 
*/
, BOOKINGS_REVENUE_TEMP AS
(
	SELECT		bt.*
				,f.name
				,f.guestcost
				,f.membercost
				,Case
					when bt.memid = 0 then	bt.Qty * f.guestcost
					when bt.memid <> 0 then	bt.Qty * f.membercost
					else 0
				End as "Revenue1"
				,Case
					when bt.memid = 0 then	bt.slots_sum * f.guestcost
					when bt.memid <> 0 then	bt.slots_sum * f.membercost
					else 0
				End as "Revenue2"
				FROM		BOOKINGS_TEMP bt
	LEFT JOIN	Facilities f	on bt.facid = f.facid
)
SELECT		br.name as "Facility"
			--,format(sum(Revenue1), 'C') as [Revenue1]
			,format(sum(Revenue2), 'C') as "Revenue2"
FROM		BOOKINGS_REVENUE_TEMP br
GROUP BY	br.name
HAVING		(sum(Revenue2) < 1000)
ORDER BY	sum(Revenue2) DESC
