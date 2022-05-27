/*
	Author:		Stuart Barnley

	Date:		26th Fenruary 2016

	Purpose:	To retrieve the latest Caffe Nero Muffin Codes Assigned
	
*/
Create procedure Staging.CaffeNero_BirthdayCodeRetrieval
As

-------------------------------------------------------------------------------------------------
-----------------------------------Find latest batch reference number----------------------------
-------------------------------------------------------------------------------------------------
Declare @MembersAssignedBatch smallint
Set @MembersAssignedBatch = (Select Max(MembersAssignedBatch) 
							 from [Relational].[RedemptionCodeAssignment])

-------------------------------------------------------------------------------------------------
------------------------------------Pull data for Marketing - NatWest----------------------------
-------------------------------------------------------------------------------------------------

Select	cc.FanID as [Customer ID], 
		c.email,
		c.ClubID,
		cc.Code as CaffeNeroBirthdayCode
from Warehouse.[Relational].[RedemptionCode] as cc
inner join warehouse.relational.customer as c
	on cc.[FanID] = c.fanid
Where c.ClubID = 132 and MembersAssignedBatch = @MembersAssignedBatch

-------------------------------------------------------------------------------------------------
------------------------------------Pull data for Marketing - RBS--------------------------------
-------------------------------------------------------------------------------------------------

Select	cc.FanID as [Customer ID], 
		c.email,
		c.ClubID,
		cc.Code as CaffeNeroBirthdayCode
from Warehouse.[Relational].[RedemptionCode] as cc
inner join warehouse.relational.customer as c
	on cc.[FanID] = c.fanid
Where c.ClubID = 138 and MembersAssignedBatch = @MembersAssignedBatch

-------------------------------------------------------------------------------------------------
--------------Pull data for Marketing - Check Dat ranges for customers selected------------------
-------------------------------------------------------------------------------------------------

Select	Min(DOB1900) as MinDate,
		Max(DOB1900) as MaxDate,
		ClubID
From (
		Select Dateadd(year,-(datepart(Year,DOB)-1900),DOB) as DOB1900,c.ClubID
		from Warehouse.[Relational].[RedemptionCode] as cc
		inner join warehouse.relational.customer as c
				on cc.[FanID] = c.fanid
		Where MembersAssignedBatch = @MembersAssignedBatch
	) as a
Group By ClubID

