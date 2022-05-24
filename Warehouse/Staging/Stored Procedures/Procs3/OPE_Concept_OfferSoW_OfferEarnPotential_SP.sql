CREATE Procedure [Staging].[OPE_Concept_OfferSoW_OfferEarnPotential_SP] (@EmailSendDate Date)
as

------------------------------------------------------------------------------------------------------
----------------------------------------Create List of Partners---------------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Partners') is not null drop table #Partners
select	p.*,
		ROW_NUMBER() OVER(ORDER BY p.PartnerID Asc) AS RowID
into #Partners
from Relational.Partner as p
Left Outer join Relational.PartnerGroups as pg
	on p.PartnerID = pg.PartnerID and UseForReport = 1
Where	pg.PartnerID is null and
		p.BrandID is not null

------------------------------------------------------------------------------------------------------
---------------------------------------Find latest Share of wallet run--------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Partner_SoWDates') is not null drop table #Partner_SoWDates
Select a.PartnerID,a.PartnerName,a.BrandID,a.BrandName,SoW.Mth,SoW.PartnerName_Formated,LastRun,StartDate,EndDate,
		ROW_NUMBER() OVER(ORDER BY a.PartnerID) AS RowNo
Into #Partner_SoWDates
from 
(
Select p.PartnerID,p.PartnerName,p.BrandID,p.BrandName,MAX(RunTime) as LastRun
From #Partners as p
inner join Warehouse.Relational.ShareofWallet_RunLog as SoW
	on ltrim(rtrim(Cast(p.PartnerID as char))) = SoW.PartnerString
Group by p.PartnerID,p.PartnerName,p.BrandID,p.BrandName
) as a
inner join Warehouse.Relational.ShareofWallet_RunLog as SoW
	on a.LastRun = SoW.RunTime
inner join Warehouse.Relational.ShareOfWallet_Dates as d
	on SoW.ID = d.ShareofWalletID
Where LastRun > Dateadd(day,-45,CAST(getdate() as DATE))

------------------------------------------------------------------------------------------------------
---------------------------------Produce SoW Average Spend per segment member-------------------------
------------------------------------------------------------------------------------------------------	
--Select * from #Partner_SoWDates as P
Declare @RowNo int, @RowMax int, @Qry nvarchar(MAX)
Set @RowNo = 1
Set @RowMax = (Select MAX(RowNo) From #Partner_SoWDates)

if object_id('tempdb..#HTM_Spends') is not null drop table #HTM_Spends
Create Table #HTM_Spends (
		PartnerID int,
		HTMID tinyint,
		Average_Daily_Spend_Pence money,
		Primary Key (PartnerID,HTMID)
		)
			
While @RowNo <= @RowMax
Begin
	Set @Qry =(Select '
	Insert into #HTM_Spends
	Select	PartnerID,
			HTMID,
			AverageYearlySpend_inPence/Datediff as Average_Daily_Spend_Pence
	from
		(Select '+Cast(PartnerID as varchar)+' as PartnerID,
				Segment as HTMID,
				Sum(PartnerSpend) as Spend,
				Count(*) as Customers,
				(Sum(PartnerSpend)/Count(*))*100 as AverageYearlySpend_inPence,
				'+Cast(DATEDIFF(day,StartDate,EndDate)+1 as varchar)+' as Datediff
		 From Warehouse.Staging.ShareOfWallet_'+PartnerName_Formated+Convert(varchar,LastRun,112)	+'
		 Group By Segment
		) as a'
		from #Partner_SoWDates Where RowNo = @RowNo)

	Set @RowNo = @RowNo+1
	
	Exec sp_executeSQL @Qry
End

------------------------------------------------------------------------------------------------------
-------------------------------------------Create list of Customers-----------------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers
Select	CINID
Into #Customers
From Warehouse.Relational.Customer as c
Left Outer join Warehouse.Relational.CINList as cl
	on c.SourceUID = cl.CIN
Where CurrentlyActive = 1

Create Clustered Index idx_Customer_CINID on #Customers (CINID)
------------------------------------------------------------------------------------------------------
-----------Pull average spend per customer per day for all active customers at all partners-----------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#NonHTM_Spends') is not null drop table #NonHTM_Spends
Create Table #NonHTM_Spends (
		PartnerID int,
		HTMID tinyint,
		Average_Daily_Spend_Pence money,
		Primary Key (PartnerID,HTMID)
		)


Declare @BrandID int,@PartnerID int,--@RowNo int, @RowMax int,
		@CustomerCount int
Set @RowNo = 1
Set @RowMax = (Select MAX(RowID) from #Partners)
Set @CustomerCount = (Select COUNT(1) From #Customers)

While @RowNo <= @RowMax
Begin
	Set @PartnerID = (Select PartnerID from #Partners where RowID = @RowNo) --- Get BrandID of Partner
	Set @BrandID = (Select BrandID from #Partners where RowID = @RowNo) --- Get BrandID of Partner

	--------------Create list of ConsumerCombinationIDs associated with Brand---------------------
	if object_id('tempdb..#CCs') is not null drop table #CCs
	Select cc.ConsumerCombinationID
	Into #CCs
	From Warehouse.Relational.ConsumerCombination as cc
	Where BrandID = @BrandID
	
	--------------Index Consumer Combination table---------------------
	Create Clustered Index idx_CCs_CCIDs on #CCs (ConsumerCombinationID)
	
	Insert into #NonHTM_Spends
	Select	@PartnerID as PartnerID,
			0 as HTMID,
			(SUM(Amount)/ 3.65)/@CustomerCount as Average_Daily_Spend_Pence
	From Warehouse.Relational.ConsumerTransaction as ct
	inner join #CCs as cc
		on ct.ConsumerCombinationID = cc.ConsumerCombinationID
	inner join #Customers as c
		on ct.CINID = c.CINID
	Where TranDate Between Dateadd(day,-370,CAST(getdate() as DATE)) and 
						   Dateadd(day,-6,CAST(getdate() as DATE))
	set @RowNo = @RowNo+1	
End

--Select * from #NonHTM_Spends
------------------------------------------------------------------------------------------------------
------------------------------------ Score each Value for Earn Potential -----------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#OfferDetails') is not null drop table #OfferDetails
Select	Distinct 
		a.IronOfferID,
		a.HTMID,
		a.Average_Daily_Spend_Pence,
		a.DatDiff,
		a.CashbackRate,
		Coalesce(a.Average_Daily_Spend_Pence*a.DatDiff*a.CashbackRate,0)
		 as EarnPotential
into	#OfferDetails
From
(
SELECT	s.IronOfferID,
		a.HTMID,
		Average_Daily_Spend_Pence,
		Case
			When s.EndDate IS null then 1
			Else DATEDIFF(DAY,s.StartDate,s.EndDate)+1
		End as DatDiff,
		Max(CommissionRate) as CashbackRate
from
(
	select * from #NonHTM_Spends
	Union All
	select * from #HTM_Spends
) as a
inner join Relational.IronOffer as i
	on	a.PartnerID = i.PartnerID
Inner Join Staging.OPE_Offers_TobeScored as s
	on	i.IronOfferID = s.IronOfferID
Inner Join Relational.IronOffer_PartnerCommissionRule as pcr
	on	s.IronOfferID = pcr.IronOfferID and
		pcr.TypeID = 1 and
		pcr.Status = 1
Group By s.IronOfferID,
		a.PartnerID,
		a.HTMID,
		Average_Daily_Spend_Pence,
		s.StartDate,
		s.EndDate
) as a
Left Outer Join (Select Distinct OfferID From Relational.PartnerOffers_Base) as POB
	on a.IronOfferID = POB.OfferID
Left Outer Join (Select Distinct OfferID From Relational.Partner_BaseOffer) as PBO
	on a.IronOfferID = PBO.OfferID
Left Outer join (select Distinct IronOfferID From Relational.Partner_NonCoreBaseOffer) as n
	on a.IronOfferID = n.IronOfferID
	
	
---------------------------------------------------------------------------------------------------------------
---------------------------------------------Create Final Scores Table-----------------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_OfferSoW_Offer_Earn_Potential') is not null 
							drop table Staging.OPE_Concept_OfferSoW_Offer_Earn_Potential

	Select	IronOfferID,HTMID,
			NTILE(100) OVER(ORDER BY EarnPotential) AS Offer_Earn_Potential
	Into Staging.OPE_Concept_OfferSoW_Offer_Earn_Potential
	from #OfferDetails as od
	Where EarnPotential > 0
	Union All
	Select	IronOfferID,HTMID,
			0 as Score
	from #OfferDetails as od
	Where EarnPotential <= 0
	Order by od.IronOfferID,od.HTMID