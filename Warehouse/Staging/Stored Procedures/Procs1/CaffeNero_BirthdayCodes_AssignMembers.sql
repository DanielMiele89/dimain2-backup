/*
	Author:			Stuart Barnley
	Date:			2015-06-29

	Purpose:		To find people who have a birthday between two dates and are emailable.
					These people are to be associated with a Voucher code for a Muffin and
					then the list is to be passed to Marketing.

	Update:			N/A


*/
CREATE Procedure Staging.CaffeNero_BirthdayCodes_AssignMembers (
								@StartDate Date,
								@EndDate Date,
								@ChunkSize int
								)
As
Declare @BStartDate Date, 
		@BEndDate Date, 
		@Codesneeded int,
		@Date Date

--Set @StartDate = '2015-07-01'
--set @EndDate = '2015-07-31'

set @BStartDate = Dateadd(year,-(datepart(Year,@StartDate)-1900),@StartDate)
Set @BEndDate = Dateadd(year,-(datepart(Year,@EndDate)-1900),@EndDate)
--Set @Chunksize = 66000

--Use Warehouse
-------------------------------------------------------------------------------------------------
----------------------------------Find Birthday Customers----------------------------------------
-------------------------------------------------------------------------------------------------
Set @Date = (select Max(Updatedate) from InsightArchive.Customer_Engagement_History)
-------------------------------------------------------------------------------------------------
----------------------------------Find Birthday Customers----------------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
select	Distinct 
		c.FanID as [Customer ID],
		c.Email,
		Dob,
		c.ClubID,
		ceh.[EngageScore],
		ceh.[Segment],
		ROW_NUMBER() OVER(ORDER BY ceh.[EngageScore] Desc) AS RowNo
Into #t1
from warehouse.relational.customer as c
inner join warehouse.relational.CustomerJourneyV2 as cj
	on	c.fanid = cj.fanid
inner join InsightArchive.Customer_Engagement_History as ceh
	on	c.FanID = ceh.FanID and
		ceh.Updatedate = @Date
Where	enddate is null and
		CustomerJourneyStatus in ('mot2','mot3','saver','redeemer') and
		marketablebyemail = 1 and
		Dateadd(year,-(datepart(Year,dob)-1900),dob) Between @BStartDate and @BEndDate and
		currentlyactive = 1
-------------------------------------------------------------------------------------------------
-----------------------------------------------Refine--------------------------------------------
-------------------------------------------------------------------------------------------------
if object_id('tempdb..#t2') is not null drop table #t2
Select *
Into #t2
From #t1
Where RowNo <= @ChunkSize

-------------------------------------------------------------------------------------------------
---------------------------------------Find unused Codes-----------------------------------------
-------------------------------------------------------------------------------------------------		

if object_id('tempdb..#codes') is not null drop table #codes
Select	ID,
		Code,
		ROW_NUMBER() OVER(ORDER BY BatchID Asc,ID) AS RowNo
Into #Codes
From	[Relational].[RedemptionCode]
Where	FanID is null

-------------------------------------------------------------------------------------------------
---------------------------------Combine codes with customers------------------------------------
-------------------------------------------------------------------------------------------------

Select c.ID,
	   t.[Customer ID]
Into #Customer_Codes
from #t2 as t
inner join #Codes as c
	on t.[RowNo] = c.RowNo

-------------------------------------------------------------------------------------------------
--------------------Create Entry in [Relational].[RedemptionCodeAssignment] table----------------
-------------------------------------------------------------------------------------------------
Insert into [Relational].[RedemptionCodeAssignment]
Select Cast(getdate()as date) as AssignedDate
-------------------------------------------------------------------------------------------------
---------------------------------Find latest [MembersAssignedBatch] ID---------------------------
-------------------------------------------------------------------------------------------------
Declare @BatchID int
Set @BatchID = (Select Max([MembersAssignedBatch]) from [Relational].[RedemptionCodeAssignment])
-------------------------------------------------------------------------------------------------
---------------------------Update Warehouse.[Relational].[RedemptionCode]------------------------
-------------------------------------------------------------------------------------------------
		
Update [Relational].[RedemptionCode]
Set		FanID = [Customer ID],
		[MembersAssignedBatch] = @BatchID
From [Relational].[RedemptionCode] as rc
inner join #Customer_Codes as cc
	on rc.id = cc.id

-------------------------------------------------------------------------------------------------
-----------------------Double check you have not overwritten existing----------------------------
-------------------------------------------------------------------------------------------------
--Select BatchID,Count(*) 
--from [Relational].[RedemptionCode]
--Where FanID is not null
--Group by BatchID
-------------------------------------------------------------------------------------------------
----------------------------------------Pull data for Marketing----------------------------------
-------------------------------------------------------------------------------------------------

--Select [Customer ID], c.email,c.ClubID,rc.Code
--from #Customer_Codes as cc
--inner join warehouse.relational.customer as c
--	on cc.[Customer ID] = c.fanid
--inner join warehouse.[Relational].[RedemptionCode] as rc
--	on c.FanID = rc.FanID
--Where c.ClubID = 132

--Select [Customer ID], c.email,c.ClubID,rc.Code
--from #Customer_Codes as cc
--inner join warehouse.relational.customer as c
--	on cc.[Customer ID] = c.fanid
--inner join warehouse.[Relational].[RedemptionCode] as rc
--	on c.FanID = rc.FanID
--Where c.ClubID = 138