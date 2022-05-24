/*
	Author:			Stuart Barnley
	Date:			18th July 2014

	Description:	Temporary table until WR has been scheduled
*/
CREATE Procedure Staging.CJ_DailyList
as

Insert into Warehouse.Staging.CustomerJourney_DailyList
select * 
--Into Warehouse.Staging.CustomerJourney_DailyList
from Relational.CustomerJourney as cj
Where StartDate = cast(Getdate() as date)