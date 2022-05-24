CREATE Procedure [Staging].[ShareOfWallet_SegmentAssignment_03_V1]
				@Partner nvarchar(40)

AS
--Set @Partner = '2365'
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------Find all runs matching PartnerString------------------------------
---------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#T1') is not null drop table #T1
select *
into #T1
from [Relational].[ShareofWallet_RunLog]
Where PartnerString = @Partner
ORDER BY ID ASC

select * from #t1
---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------Latest run for HTM------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#T2') is not null drop table #T2
Select	a.PartnerString,--t.RunDate,
		t.id,
		ROW_NUMBER() OVER(ORDER BY ID ASC) AS RowNo
into #t2
 from 
#T1 as t
inner join 
(select PartnerString,Max(RunTime) as lastrun
from #T1 as a
Group by PartnerString
) a
	on t.PartnerString = a.PartnerString and t.RunTime = a.LastRun

	select * from #t2
--------------------------------------------------------------------------------------------------------------------
------------------Create tempoary table of all Competitors----------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
declare @RowNo int,@PartnerString varchar(50),@HeadroomID int
set @RowNo = 1 
if object_id('tempdb..#CB') is not null drop table #CB
Create Table #CB (ShareOfWalletID Int,CompetitorID Int,CompetitorName nvarchar(150))

While @RowNo <= (Select Max(RowNo) from #t2)  
Begin
	Set @PartnerString = (Select PartnerString from #t2 where RowNo = @RowNo)
	Set @HeadroomID = (Select ID from #t2 where RowNo = @RowNo)

	if object_id('tempdb..#PartnerIDs') is not null drop table #PartnerIDs
	Select LEFT(@PartnerString,4) as PartnerID into #PartnerIDs
	Insert into #PartnerIDS Select Right(LEFT(@PartnerString,9),4) as PartnerID where len(@PartnerString) > 4
	Insert into #PartnerIDS Select Right(LEFT(@PartnerString,14),4) as PartnerID where len(@PartnerString) > 9
	Insert into #PartnerIDS Select Right(LEFT(@PartnerString,19),4) as PartnerID where len(@PartnerString) > 14
	Insert into #PartnerIDS Select Right(LEFT(@PartnerString,24),4) as PartnerID where len(@PartnerString) > 19
	Insert into #PartnerIDS Select Right(LEFT(@PartnerString,29),4) as PartnerID where len(@PartnerString) > 24

	Insert into #CB
	Select Distinct @HeadroomID as ShareOfWalletID,
					B.Brandid as CompetitorID,
					B.BrandName as CompetitorName
	from Staging.Partners_incFuture as p
	inner join relational.brandcompetitor as bc
		on p.Brandid = bc.BrandID
	inner join Relational.Brand as b
		on bc.CompetitorID = b.BrandID
	where p.partnerid in (Select Cast(PartnerID as int) from  #PartnerIDs)

	Set @RowNo = @RowNo+1
End

select * from #cb

--------------------------------------------------------------------------------------------------------------------
------------------------------Insert into Realtional Table---------------------------------------
--------------------------------------------------------------------------------------------------------------------
--Create Table Warehouse.[Relational].[ShareofWallet_BrandCompetitorLog] 
--		([ID] [int] IDENTITY(1,1) NOT NULL, ShareOfWalletID Int not null,CompetitorID Int not null,CompetitorName nvarchar(150) not null)
Insert into [Relational].[ShareOfWallet_BrandCompetitorLog] 
Select Distinct * 
from #CB
Where ShareOfWalletID not in (Select Distinct ShareOfWalletID from [Relational].[ShareOfWallet_BrandCompetitorLog])