/*
	Author:			Stuart Barnley

	Date:			17-11-2015

	Purpose:		To provide a list of customers who have opened a MyRewards credit
					card, this is sent to a mailhouse so they can be sent the 
					introductory information.

	Updates:		N/A


*/
CREATE Procedure Staging.DMCreditCardOpeners_ForMailhouse
as


Declare @Date Date,
		@Startdate date, -- Is used to hold the date the cards should have been added from
		@EndDate date,-- Is used to hold the date the cards should have been added by
		@TableName varchar(300),-- This is the name of the new data table that will be created
		@Qry nvarchar(500) -- This is used to hold any query that needs to be generated then run

Set @Date = GetDate()
Set @TableName = 'Warehouse.InsightArchive.CreditCardOpenerCustomers_'+
													Convert(varchar,Getdate(),112)

----------------------------------------------------------------------------------
-------------Use todays date to go back and select customers ---------------------
----------------------------------------------------------------------------------
set Datefirst 1
Set @StartDate = DateAdd(day,-11,(select [Staging].[fnGetStartOfWeek](@Date)))
Set @EndDate = DateAdd(day,6,@StartDate)
Select @StartDate,@EndDate

----------------------------------------------------------------------------------
-------------- Select the customers that need to be contacted --------------------
----------------------------------------------------------------------------------

Select	CustomerID,
		Brand,
		Max([Private]) as [Private],
		Title,
		Firstname,
		Lastname,
		Address1,
		Address2,
		City,
		County,
		Postcode,
		Max([Type]) as [Type]
Into #t1
from (
select 	c.FanID as CustomerID,
		Case
			When c.ClubID = 132 then 'NatWest'
			When c.ClubID = 138 then 'RBS'
		End as Brand,
		Case
			When r.CustomerSegment is null then 'N' -- Core
			When r.CustomerSegment = 'V' then 'Y'   -- Private
			Else 'N'
		End as [Private],
		ltrim(rtrim(Title)) as Title,
		ltrim(rtrim(Firstname)) as Firstname,
		ltrim(rtrim(Lastname)) as Lastname,
		Address1,
		Address2,
		City,
		County,
		c.Postcode,
		Case
			When Cast(ActivatedDate as date) < Dateadd(day,-2,Cast(pc.Date as Date)) then 'A' -- Adding card to scheme
			Else 'O'		-- New Joiner with a card
		End as [Type]
From SLC_Report.dbo.Pan p with (nolock) 
inner join Warehouse.Relational.Customer c with (nolock) 
	on p.UserID = c.FanID
inner join slc_report.dbo.PaymentCard as pc
	on	p.PaymentCardID = pc.id
inner join Warehouse.Relational.Customer_RBSGSegments as r
	on	c.FanID = r.FanID and
		r.EndDate is null
inner join warehouse.relational.CAMEO as cam
	on c.postcode = cam.Postcode
Left Outer join (Select [FanID] from Warehouse.[InsightArchive].[CreditCardOpeners] Where SendDate > dateadd(day,-35,@Date)) as a
	on c.FanID = a.FanID
Where	p.AffiliateID = 1 and 
		pc.CardTypeID = 1 and
		Cast(p.AdditionDate as date) Between @StartDate and @EndDate and
		c.CurrentlyActive = 1 and
		(c.EmailStructureValid = 0 or c.ActivatedOffline = 1) and
		pc.Date = AdditionDate and
		Len(c.FirstName) > 1 and
		Len(c.Lastname) > 1 and p.RemovalDate is null and
		a.FanID is null
) as a
Group By CustomerID,Brand,Title,Firstname,Lastname,Address1,Address2,City,County,Postcode

------------------------------------------------------------------------------------
-- Create table of data - Warehouse.InsightArchive.CreditCardOpenerCustomers_XXXX---
------------------------------------------------------------------------------------

Set @Qry = '
Select * 
Into ' + @TableName + ' 
From #t1'

Exec sp_ExecuteSQL @Qry

------------------------------------------------------------------------------------
----------- Add entries to - Warehouse.InsightArchive.CreditCardOpeners ------------
------------------------------------------------------------------------------------
Set @Qry = '
Insert Into Warehouse.InsightArchive.CreditCardOpeners 
Select	CustomerID as FanID,
		Brand,
		[Private],
		[Type],
		Cast('''+Convert(Varchar,@Date,120)+''' as Date) as [SendDate]
From '+@TableName

Exec sp_ExecuteSQL @Qry

------------------------------------------------------------------------------------
-------------------------------------- Display Table Contents ----------------------
------------------------------------------------------------------------------------

Set @Qry = 'Select * From ' + @TableName

Exec sp_ExecuteSQL @Qry