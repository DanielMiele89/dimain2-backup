/*

Author:			Stuart Barnley
Date:			03/03/2014
Purpose:		Created to replace Headroom Targeting Model but using some of the technology
				
Notes:			This will use new CardTransaction replacement

Updates:		31-07-2014 SB - Looking for trans based on EndDate Table (Staging.ShareofWallet_EndDate)
				02-12-2015 SB - Create to run SoW for date minus 35 days

*/

CREATE Procedure [Staging].[ShareOfWallet_SegmentAssignment_Prior35_01_V1_2]
				 @PartnerString varchar(200)
With Execute as owner
as
Declare @tablename nvarchar(250),@Qry nvarchar(max),@Mths int
--------------------------------------------------------------------------------------------------------------
---------------------------------Create PartnerIDs table------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PartnerIDs') is not null drop table #PartnerIDs
Select LEFT(@PartnerString,4) as PartnerID into #PartnerIDs
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,9),4) as PartnerID where len(@PartnerString) > 4
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,14),4) as PartnerID where len(@PartnerString) > 9
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,19),4) as PartnerID where len(@PartnerString) > 14
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,24),4) as PartnerID where len(@PartnerString) > 19
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,29),4) as PartnerID where len(@PartnerString) > 24
--select * from #PartnerIDs
--------------------------------------------------------------------------------------------------------------
---------------------------------Find number of months for data assessment------------------------------------
--------------------------------------------------------------------------------------------------------------

Set @Mths = (Select MAX(Mth) from Staging.ShareOfWallet_PartnerSettings as a--Staging.PartnerSegmentAssessmentMths as a
inner join #PartnerIDs as b
	on a.PartnerID = b.PartnerID)


Set @tablename = 'Staging.HeadroomEligible'+ Cast(@Mths as varchar(2))+'Mths'
if object_id('tempdb..##CustomerBase') is not null drop table ##CustomerBase
Set @Qry = 'select * into ##CustomerBase from ' + @tablename

--Select @PartnerString,@TableName,@Qry

Exec sp_ExecuteSQL @Qry

--------------------------------------------------------------------------------------------------------------
----------------------------------Find Brand IDs of Partners and Competitors----------------------------------------
--------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PartnerBrandIDs') is not null drop table #PartnerBrandIDs
select b.BrandID,p.BrandName,1 as PartnerBrand
into #PartnerBrandIDs
from relational.brand as b
inner join Staging.Partners_IncFuture as p
	on b.BrandID = p.BrandID
where p.PartnerID in (select distinct PartnerID from #PartnerIDs)

if object_id('tempdb..#CompetitorBrandIDs') is not null drop table #CompetitorBrandIDs
select distinct c.CompetitorID,b.BrandName , 0 as PartnerBrand
into #CompetitorBrandIDs
from Relational.BrandCompetitor as c
inner join relational.Brand as b
	on c.CompetitorID = b.BrandID
where c.BrandID in (Select distinct BrandID from #PartnerBrandIDs)
--------------------------------------------------------------------------------------------------------------
--------------------------------------------Combine Brand Lists-----------------------------------------------
--------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#BrandIDs') is not null drop table #BrandIDs
Select * 
Into #BrandIDs
From
(Select * from #PartnerBrandIDs
Union all 
Select * from #CompetitorBrandIDs
) as a
--------------------------------------------------------------------------------------------------------------
---------------------------------------Produce list of Consumer Combinations----------------------------------
--------------------------------------------------------------------------------------------------------------
Select	B.*,
		cc.ConsumerCombinationID
into #ConCom
from #BrandIDs as b
inner join Relational.ConsumerCombination as cc
	on b.BrandID = cc.BrandID
--------------------------------------------------------------------------------------------------------------
--------------------------------------------Drop Unneeded Tables----------------------------------------------
--------------------------------------------------------------------------------------------------------------
Drop table #PartnerIDs
Drop table #PartnerBrandIDs
Drop Table #CompetitorBrandIDs


--------------------------------------------------------------------------------------------------------------
--------------------------Pull Brand Defined transactions within the timescale required-----------------------
--------------------------------------------------------------------------------------------------------------

Declare @StartDate date,@EndDate date--,@Mths smallint
--Set @Mths = 6

Set @EndDate = (Select EndDate From Staging.ShareofWallet_EndDate)
Set @EndDate = DATEADD(day,-35,@EndDate)
Set @StartDate = DateAdd(Day,1,DateAdd(month,-@Mths,@EndDate))
Select @EndDate,@StartDate
--**********Set @StartDate = dateadd(month,-@Mths,cast (dateadd(day,-(datepart(day,GETDATE())-1),GETDATE())as DATE))
--**********Set @EndDate = cast(dateadd(day,-datepart(day,GETDATE()),GETDATE())as DATE)

--Select @StartDate,@EndDate
if object_id('tempdb..#Transactions') is not null drop table #Transactions
Select FileID,RowNum,cast(ct.TranDate as DATe) as TranDate,ct.CINID,--ct.BrandMIDID,bm.BrandID,
		cc.BrandID,cc.PartnerBrand,ct.Amount
into #Transactions
from Relational.ConsumerTransaction as ct with (nolock)
inner join ##CustomerBase as c
	on ct.CINID = c.CINID
inner join #ConCom as cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
Where TranDate >= @StartDate and TranDate < Dateadd(day,1,@EndDate)
--------------------------------------------------------------------------------------------------------------
-----------------------------------------Add Holding Table data-----------------------------------------------
--------------------------------------------------------------------------------------------------------------
Insert into #Transactions
Select FileID,RowNum,cast(ct.TranDate as DATe) as TranDate,ct.CINID,--ct.BrandMIDID,bm.BrandID,
		cc.BrandID,cc.PartnerBrand,ct.Amount
from Relational.ConsumerTransactionHolding as ct with (nolock)
inner join ##CustomerBase as c
	on ct.CINID = c.CINID
inner join #ConCom as cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
Where TranDate >= @StartDate and TranDate < Dateadd(day,1,@EndDate)
  
--------------------------------------------------------------------------------------------------------------
--------------------------------Roll Up Transactions to Customer Level----------------------------------------
--------------------------------------------------------------------------------------------------------------	
if object_id('tempdb..#CustCategorySpend') is not null drop table #CustCategorySpend
Select	CinID,
		Sum(Case 
			When PartnerBrand = 1 then Amount
			Else 0
		End) as PartnerSpend,
		SUM(Amount) as CategorySpend
Into #CustCategorySpend
From #Transactions as t
Group by CINID

--------------------------------------------------------------------------------------------------------------
--------------------------------------------Drop Unneeded Tables----------------------------------------------
--------------------------------------------------------------------------------------------------------------
Drop table #Transactions
Drop table #BrandIDs
--------------------------------------------------------------------------------------------------------------
--------------------------------Roll Up Transactions to Customer Level----------------------------------------
--------------------------------------------------------------------------------------------------------------	
Declare @TableName2 nvarchar(200)
Set @TableName2 = 'staging.Headroom_ActSpend'+ cast(@Mths as varchar(2))+ 'Mths'
Set @Qry = 
'if object_id('+Char(39)+@TableName2+Char(39)+') is not null drop table ' + @TableName2+ '
 Select a.CINID,
		Case
			When b.CINID IS null then '+char(39)+'Not Eligible'+CHAR(39)+'
			Else '+Char(39)+'Eligible'+Char(39)+'
		End Eligibility,
		isnull(ccs.PartnerSpend,0) as PartnerSpend,
		isnull(ccs.CategorySpend,0) as CategorySpend
 Into ' + @TableName2 +'
 from Staging.Headroom_ActInitialBase as a with (nolock)
 left outer join ' + @TableName + ' as b
	on a.cinid = b.cinid
 Left Outer join #CustCategorySpend as ccs
	on a.CINID = ccs.CINID'

Exec sp_Executesql @Qry

--------------------------------------------------------------------------------------------------------------
--------------------------------------------Drop Unneeded Tables----------------------------------------------
--------------------------------------------------------------------------------------------------------------
Drop table #CustCategorySpend