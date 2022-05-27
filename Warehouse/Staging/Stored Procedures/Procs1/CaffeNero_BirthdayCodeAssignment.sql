/*
	Author:			Stuart Barnley
	Date:			2015-04-20

	Purpose:		To find people who have a birthday between two dates and are emailable.
					These people are to be associated with a Voucher code for a Muffin and
					then the list is to be passed to Marketing.

	Update:			20-04-2015 SB - Version 1


*/

Create Procedure Staging.CaffeNero_BirthdayCodeAssignment (@SDate Date,@EDate date, @CodesToAssign int)
As 

-------------------------------------------------------------------------------------------------
-------------------------------Assign Parameters to internal Variables---------------------------
-------------------------------------------------------------------------------------------------


Declare		@StartDate date, 
			@EndDate Date, 
			@BStartDate Date, 
			@BEndDate Date, 
			@Codesneeded int,
			@Date Date,
			@ChunkSize int

Set @StartDate = @SDate 
set @EndDate = @EDate

set @BStartDate = Dateadd(year,-(datepart(Year,@StartDate)-1900),@StartDate)
Set @BEndDate = Dateadd(year,-(datepart(Year,@EndDate)-1900),@EndDate)
Set @Chunksize = @CodesToAssign

-------------------------------------------------------------------------------------------------
----------------------------------Find Birthday Customers----------------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
select	Distinct 
		c.FanID as [Customer ID],
		c.Email,
		Dob,
		c.ClubID
Into #t1
from warehouse.relational.customer as c
Where	marketablebyemail = 1 and
		Dateadd(year,-(datepart(Year,dob)-1900),dob) Between @BStartDate and @BEndDate and
		currentlyactive = 1

-------------------------------------------------------------------------------------------------
-------------------------------For customers find earn at MyRewards Partners---------------------
-------------------------------------------------------------------------------------------------
Select	c.[Customer ID],
		Sum(CashbackEarned) as TotalEarned
Into #pt
From #t1 as c
inner join Relational.PartnerTrans as pt
	on c.[Customer ID] = pt.FanID
Where TransactionDate between dateadd(day,-72,Cast(getdate() as Date)) and dateadd(day,-2,Cast(getdate() as Date))
Group by c.[Customer ID]

-------------------------------------------------------------------------------------------------
--------------------------------For customers find RBS funded earnings---------------------------
-------------------------------------------------------------------------------------------------
Select	c.[Customer ID],
		Sum(CashbackEarned) as TotalEarned
Into #Aca
From #t1 as c
inner join Relational.AdditionalCashbackAward as pt
	on c.[Customer ID] = pt.FanID
Where TranDate between dateadd(day,-72,Cast(getdate() as Date)) and dateadd(day,-2,Cast(getdate() as Date))
Group by c.[Customer ID]

-------------------------------------------------------------------------------------------------
--------------------------------Combine Earnings at select top customers------------------------
-------------------------------------------------------------------------------------------------

Select * 
Into #Customer
from 
(
Select	*,
		ROW_NUMBER() OVER (ORDER BY Total Desc) AS RowNumber
From (
Select	t.[Customer ID],
		t.ClubID,
		--Sum(pt.TotalEarned) as pt_Earned,
		--Sum(a.TotalEarned) as aca_Earned,
		coalesce(Sum(a.TotalEarned),0)+coalesce(Sum(pt.TotalEarned),0) As Total
From #t1 as t
left Outer join #pt as pt
	on t.[Customer ID] = pt.[Customer ID]
left outer join #Aca as a
	on t.[Customer ID] = a.[Customer ID]
Group by t.[Customer ID],t.ClubID
) as a
) as a 
Where RowNumber <= @ChunkSize

-------------------------------------------------------------------------------------------------
---------------------------------------Find unused Codes-----------------------------------------
-------------------------------------------------------------------------------------------------		

if object_id('tempdb..#codes') is not null drop table #codes
Select	ID,
		Code,
		ROW_NUMBER() OVER(ORDER BY a.BatchID Asc,ID) AS RowNo
Into #Codes
From	[Relational].[RedemptionCode] as a
inner join [Relational].RedemptionCodeBatch as b
	on	a.BatchID = b.BatchID
inner join [Relational].RedemptionCodeType as t
	on	b.CodeTypeID = t.CodeTypeID
Where	FanID is null and
		t.CodeTypeID = 1
-------------------------------------------------------------------------------------------------
---------------------------------Combine codes with customers------------------------------------
-------------------------------------------------------------------------------------------------

Select c.ID,
	   t.[Customer ID]
Into #Customer_Codes
from #Customer as t
inner join #Codes as c
	on t.[RowNumber] = c.RowNo

--------------------------------------------------------------------------------------------------
---------------------------Update Warehouse.[Relational].[RedemptionCode]------------------------
-------------------------------------------------------------------------------------------------
		
Update [Relational].[RedemptionCode]
Set FanID = [Customer ID]
From [Relational].[RedemptionCode] as rc
inner join #Customer_Codes as cc
	on rc.id = cc.id
-------------------------------------------------------------------------------------------------
-----------------------Add Entry to Redemptions Code Assignemnt table----------------------------
-------------------------------------------------------------------------------------------------
Insert into [Relational].[RedemptionCodeAssignment]
Select Cast(getdate() as Date)

-------------------------------------------------------------------------------------------------
----------------------Find latest entry inRedemptions Code Assignemnt table----------------------
-------------------------------------------------------------------------------------------------
Declare @MembersAssignedBatch smallint
Set @MembersAssignedBatch = (Select Max(MembersAssignedBatch) from [Relational].[RedemptionCodeAssignment])


Update [Relational].[RedemptionCode]
Set MembersAssignedBatch = @MembersAssignedBatch
Where fanid is not null and MembersAssignedBatch is null

