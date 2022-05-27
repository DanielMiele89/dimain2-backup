/*
Author:		Stuart Barnley
Date:		18/03/2013
Purpose:	Extract transactions that are at a partner or partner group, their named competitors and 
			transactions with a MCC from a determined list. These will be used
			to calculate the EPOCU of the customer base.
Run Time:	

Notes:		Using CardTransaction as it is now fully available
			
*/

--use Warehouse

CREATE Procedure [Staging].[EPOCU_Calculation]
		@StartDate date, -- Date the Transactions should be assessed from
		@EndDate date,	 -- Date the Transactions should be assessed to
		@PartnerString as varchar(200), -- a comma seperated string containing all the Partners to be assessed as one group,
		@CustType as char(1),
		@CustTableName as varchar(Max), -- This field will hold the query that pulls the customer base
		@MCC as bit,
		@Output_NE as char(1),
		@OutputTable as varchar(Max)
as
------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------Declare Main Variables for use-----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
/*Declare @StartDate date, -- Date the Transactions should be assessed from
		@EndDate date,	 -- Date the Transactions should be assessed to
		@PartnerString as varchar(200) -- a comma seperated string containing all the Partners to be assessed as one group
Set @StartDate = 'Mar 01, 2012'
Set @EndDate = 'Feb 28, 2013'
--Set @PartnerString = '4001,2432,2431,3866,3612' ---- Dixons Group 
Set @PartnerString = '3770'
*/
--***********************Store the variables in tables for use throughout the code
if object_id('tempdb..#Dates') is not null drop table #Dates
Select @StartDate as StartDate, @EndDate as EndDate into #Dates
if object_id('tempdb..#PartnerIDs') is not null drop table #PartnerIDs
Select LEFT(@PartnerString,4) as PartnerID into #PartnerIDs
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,9),4) as PartnerID where len(@PartnerString) > 4
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,14),4) as PartnerID where len(@PartnerString) > 9
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,19),4) as PartnerID where len(@PartnerString) > 14
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,24),4) as PartnerID where len(@PartnerString) > 19
Insert into #PartnerIDS Select Right(LEFT(@PartnerString,29),4) as PartnerID where len(@PartnerString) > 24
select * from #PartnerIDs

/*------------------------------------------------------------------------
-----------Select Customer Base--------------------------------------------
--------------------------------------------------------------------------*/
--Pull out the Customer Base from list of CINs in a table
if object_id('tempdb..##customerbase') is not null drop table ##customerbase
Declare --@CustTableName as varchar(Max), --- This field holds the name of the table containing the CINs to have EPOCU assessed
		@ExtraTableCode as varchar(max),
		@Qry_CustomerBase as varchar(max) --- This field will hold the query that pulls the customer base
--Set		@CustTableName = 'Sandbox.Stuart.RBSG_Seed_Records_2013March'
--Set		@CustTableName = ''
Set		@ExtraTableCode = Case
								When LEN(@CustTableName) > 0 then 'inner join ' + @CustTableName + ' as a on CIN.CINID = a.CINID'
								When @CustType = 'S' then 'inner join relational.customer  as c on CIN.CIN = C.SourceUID'
								When @CustType = 'R' then 'inner join relational.customer  as c on CIN.CIN = C.SourceUID 
														   inner join Relational.ReportBaseMay2012  as rb on C.Compositeid = rb.compositeid'
								Else ''
						    End
Set		@Qry_CustomerBase =
'select  CIN.CINID
into	##customerbase
from	Relational.CINList as CIN ' + @ExtraTableCode

--(101 row(s) affected)
Select @Qry_CustomerBase
exec(@Qry_CustomerBase)
create clustered index i_CINID on ##customerbase (CINID)	
--0 sec
Select * from ##customerbase
--***************************Select top 100 * from #customerbase
/*------------------------------------------------------------------------
-------------------------Partner Brand IDs--------------------------------
--------------------------------------------------------------------------*/
--Pull out a list of the BrandIDs from the Brand table for the Dixons group partner records
if object_id('tempdb..#PartnerBrandIDs') is not null drop table #PartnerBrandIDs
select b.BrandID,p.BrandName 
into #PartnerBrandIDs
from relational.brand as b
inner join Staging.Partners_IncFuture as p
	on b.BrandID = p.BrandID
where p.PartnerID in (select distinct PartnerID from #PartnerIDs)

Select * from #PartnerBrandIDs

/*----------------------------------------------------------------------------------------
-------------Select Transactions based on MIDs identified by MIDI-------------------------
------------------------------------------------------------------------------------------*/

if object_id('tempdb..#PartnerTrans_CT') is not null drop table #PartnerTrans_CT
Select FileID,RowNum,cast(ct.TranDate as DATe) as TranDate,ct.CINID,ct.BrandMIDID,Amount
into #PartnerTrans_CT
from Relational.CardTransaction as ct with (nolock)
inner join ##customerbase as c
	on ct.CINID = c.CINID
inner join relational.BrandMID as BM
	on ct.BrandMIDID = BM.BrandMIDID
Where TranDate >= (select StartDate from #Dates) and TranDate < Dateadd(day,1,(select EndDate from #Dates)) and
	  BM.BrandID in (Select distinct BrandID from #PartnerBrandIDs)
--(33 row(s) affected) - B&Q

/*-----------------------------------------------------------------------------------------
----------------------Write retailer Trans (Non GAS) to Table------------------------------
-----------------------------------------------------------------------------------------*/
--Write the contents to a table on Sandbox as it will be used later for the final EPOCU calculation

if object_id('Staging.EPOCU_Assessment_Transactions_CT') is not null drop table Staging.EPOCU_Assessment_Transactions_CT
Select *
into Staging.EPOCU_Assessment_Transactions_CT
from #PartnerTrans_CT
--(33 row(s) affected)
/*---------------------------------------------------------------------------------------
----------------------------Pull out a list of competitors-------------------------------
-----------------------------------------------------------------------------------------*/
--Use BrandIDs identified to find out competitor brands
if object_id('tempdb..#CompetitorBrandIDs') is not null drop table #CompetitorBrandIDs
select distinct c.CompetitorID--,b.BrandName 
into #CompetitorBrandIDs
from Relational.BrandCompetitor as c
inner join relational.Brand as b
	on c.CompetitorID = b.BrandID
where c.BrandID in (Select distinct BrandID from #PartnerBrandIDs)
--(28 row(s) affected) -B&Q
/*
  */
Select c.*,b.BrandName from #CompetitorBrandIDs as c
inner join relational.Brand as b
	on c.CompetitorID = b.BrandID
/*---------------------------------------------------------------------------------------
-------------------Write retailer Competitor Trans to temporary Table--------------------
-----------------------------------------------------------------------------------------*/
--Pull out all those transactions from CardTransaction that are at the competitor brands
if object_id('tempdb..#CompetitorTrans_CT') is not null drop table #CompetitorTrans_CT
Select FileID,RowNum,cast(ct.TranDate as DATe) as TranDate,ct.CINID,ct.BrandMIDID,Amount,bm.BrandID
into #CompetitorTrans_CT
from Relational.CardTransaction as ct with (nolock)
inner join ##customerbase as c
	on ct.CINID = c.CINID
inner join relational.BrandMID as BM
	on ct.BrandMIDID = BM.BrandMIDID
Where TranDate >= (select StartDate from #Dates) and TranDate < Dateadd(day,1,(select EndDate from #Dates)) and
	  BM.BrandID in (Select distinct CompetitorID from #CompetitorBrandIDs)
--(108 row(s) affected) - B&Q
/*-----------------------------------------------------------------------------------------
---------------------Write Competitor retailer Trans to Table------------------------------
-----------------------------------------------------------------------------------------*/
--Write the contents to a table on Sandbox as it will be used later for the final EPOCU calculation

if object_id('Staging.EPOCU_Assessment_Comp_Transactions_CT') is not null drop table Staging.EPOCU_Assessment_Comp_Transactions_CT
Select *
into Staging.EPOCU_Assessment_Comp_Transactions_CT
from #CompetitorTrans_CT
--(108 row(s) affected)

/*-----------------------------------------------------------------------------------------------
---------------------------------------Find MCCs for Partners -----------------------------------
-----------------------------------------------------------------------------------------------*/
if object_id('tempdb..#PartnerMCCs') is not null drop table #PartnerMCCs
Select Distinct m.MerchantCatCode
into #PartnerMCCs
from #PartnerBrandIDs as b
inner join staging.Partners_IncFuture as p
	on b.BrandID = p.BrandID
inner join relational.PartnerMCC as m
	on p.PartnerID = m.PartnerID
--B&Q - 5198, 5200, 5211, 5231, 5251, 5261

select * from #PartnerMCCs
/*-----------------------------------------------------------------------------------------------
---------------MCC Transactions - Run section in one go from Here--------------------------------
-----------------------------------------------------------------------------------------------*/


--select * from #PartnerMCCs

declare @IntList varchar(max)

select @IntList = (select Merchantcatcode  + ',' as [text()]
            from #PartnerMCCs
            for xml path(''))
            
select @IntList = LEFT(@IntList, LEN(@IntList) - 1)

Select @IntList

--Transactions made by customer base where the transaction has a specific MCC and not at one
--of the previous established brands (Partner or competitors)

DECLARE @Query as Varchar(Max)
if object_id('Staging.EPOCU_Assessment_MCC_Transactions_CT') is not null Drop Table Staging.EPOCU_Assessment_MCC_Transactions_CT
set @Query = 
			Case
				When @MCC = 1 then
					'Select FileID,RowNum,cast(ct.TranDate as DATe) as TranDate,ct.CINID,ct.BrandMIDID,Amount,bm.BrandID
					 into Staging.EPOCU_Assessment_MCC_Transactions_CT
					 from Warehouse.Relational.CardTransaction as ct with (nolock)
					 inner join ##customerbase as c
							on ct.CINID = c.CINID
					 inner join Warehouse.relational.BrandMID as BM
							on ct.BrandMIDID = BM.BrandMIDID
					 Left Outer Join #CompetitorBrandIDs as com
							on bm.BrandID = com.CompetitorID
					 Left Outer Join #PartnerBrandIDs as PB
							on bm.BrandID = pb.BrandID
					 Where	TranDate >= (select StartDate from #Dates) and TranDate < Dateadd(day,1,(select EndDate from #Dates)) and
							com.CompetitorID is null and
							pb.BrandID is null and
							MCC in (' + @IntList+')'
				Else
					'CREATE TABLE [Staging].[EPOCU_Assessment_MCC_Transactions_CT](
						[FileID] [int] NOT NULL,
						[RowNum] [int] NOT NULL,
						[TranDate] [date] NULL,
						[CINID] [int] NULL,
						[BrandMIDID] [int] NOT NULL,
						[Amount] [money] NOT NULL,
						[BrandID] [smallint] NOT NULL
					 ) ON [PRIMARY]'
			End
	  
select @Query
exec(@Query)
--(67 row(s) affected) - B&Q
--
Select --COUNT(*) 
* from Staging.EPOCU_Assessment_MCC_Transactions_CT as ct
inner join warehouse.relational.BrandMID as bm
	on bm.BrandMIDID = ct.brandmidid
inner join warehouse.relational.Brand as b
	on bm.BrandID = b.BrandID
Order by CINID
/*-----------------------------------------------------------------------------------------------
---------------MCC Transactions - Run section in one go to Here----------------------------------
-----------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------
--------------------------Competitor Transactions roll-up by Brand-----------------------
---------------------------------------------------------------------------------------*/
--For each customer I have Summed Transactions spend per Brand for EPOCU assessment
if object_id('Staging.EPOCU_Assessment_Comp_Transactions_CT_Rollup') is not null drop table Staging.EPOCU_Assessment_comp_Transactions_CT_Rollup
Select CINID,BrandID,SUM(Amount) as TranSum,COUNT(*) as TranCount
Into Staging.EPOCU_Assessment_Comp_Transactions_CT_Rollup
from Staging.EPOCU_Assessment_Comp_Transactions_CT
Group by CINID,BrandID
--(41 row(s) affected) - B&Q
/*---------------------------------------------------------------------------------------
--------------------------------------------EPOCU Calculation----------------------------
---------------------------------------------------------------------------------------*/
--Assess PartnerSpend against Competitor and (in the case of C and U MCC spend to come up 
--with the appropriate EPOCU segmentation
Delete from EPOCU_Assessment_MCC_Transactions_CT where @MCC = 0

if object_id('tempdb..#Group_EPOCU') is not null drop table #Group_EPOCU
Select	a.*,
		Case
			When a.PartnerSpend <= 0 and a.CompetitorSpend+MCCSpend <= 0 then 'U'
			When a.PartnerSpend <= 0 and a.CompetitorSpend+MCCSpend > 0 then 'C'
			When a.PartnerSpend > 0 and a.CompetitorHighestSpend <= 0 then 'E'
			When a.PartnerSpend >= CompetitorHighestSpend -- and CompetitorSpend > 0 
					then 'P'
			When a.PartnerSpend < CompetitorHighestSpend --and a.PartnerSpend > 0  
					then 'O'
			Else 'Z'
		End as EPOCU
into #Group_EPOCU
from
(Select	C.CINID,
		coalesce(D.TotalSpend,0)	as PartnerSpend,
		Coalesce(D.TranCount,0)		as PartnerTrans,
		coalesce(E.TotalSpend,0)	as CompetitorSpend,
		coalesce(E.TranCount,0)		as CompetitorTrans,
		coalesce(E.HighestSpend,0)	as CompetitorHighestSpend,
		coalesce(F.TotalSpend,0)	as MCCSpend,
		coalesce(F.TranCount,0)		as MCCTrans
from ##Customerbase as c
Left Outer join 
(	Select CinID,SUM(Amount) as TotalSpend,COUNT(1)as TranCount
	from Staging.EPOCU_Assessment_Transactions_CT
	Group by CinID
) as d on c.CINID = d.CINID
left outer join
(	Select CinID,SUM(TranSum) as TotalSpend,Max(TranSum) as HighestSpend,SUM(TranCount) as TranCount
	from Staging.EPOCU_Assessment_Comp_Transactions_CT_Rollup
	Group by CinID
) as e on c.CINID = e.CINID
left outer join 
(	Select CinID,SUM(Amount) as TotalSpend,COUNT(*) as TranCount
	from Staging.EPOCU_Assessment_MCC_Transactions_CT 
	Group by CinID
)as f on c.CINID = f.CINID

) as a
Order by EPOCU
--(44 row(s) affected)
/*select e.*
from #Group_EPOCU as e
Order by cinid

*/
Set		@Qry_CustomerBase =
							Case when @Output_NE = 'E' then 

								'Insert into ' + @OutputTable + '
								Select e.CinID,
								 c.CompositeID,
								 e.PartnerSpend,
								 e.PartnerTrans,
								 e.CompetitorSpend,
								 e.CompetitorTrans,
								 e.CompetitorHighestSpend,
								 e.MCCSpend,
								 e.MCCTrans,
								 e.EPOCU,
								 p.PartnerID
								 from #Group_EPOCU as e
								 inner join warehouse.relational.CINList as cl
									on e.cinid = cl.cinid
								 inner join warehouse.relational.Customer as c
									on cl.CIN = c.sourceuid	,
								 #PartnerIDs as p'
							Else 
								'Select e.CinID,
								 c.CompositeID,
								 e.PartnerSpend,
								 e.PartnerTrans,
								 e.CompetitorSpend,
								 e.CompetitorTrans,
								 e.CompetitorHighestSpend,
								 e.MCCSpend,
								 e.MCCTrans,
								 e.EPOCU,
								 p.PartnerID
								 into ' + @OutputTable + '
								 from #Group_EPOCU as e
								 inner join warehouse.relational.CINList as cl
									on e.cinid = cl.cinid
								 inner join warehouse.relational.Customer as c
									on cl.CIN = c.sourceuid	,
								 #PartnerIDs as p'
							End
Select @Qry_CustomerBase
exec(@Qry_CustomerBase)

--Select * from Sandbox.Stuart.RBSG_Seed_Records_2013March_EPOCU

/*---------------------------------------------------------------------------------------
--------------------------------------------EPOCU Assessment----------------------------
---------------------------------------------------------------------------------------*/
--Work out the counts per EPOCU Segment
--Use Warehouse
/*select	EPOCU as New_Segment, 
		count(*) as CustomerCount 
from #Group_EPOCU as d
group by EPOCU
Order by  
	   case
			When EPOCU = 'E' then 1
			When EPOCU = 'P' then 2
			When EPOCU = 'O' then 3
			When EPOCU = 'C' then 4
			When EPOCU = 'U' then 5
			Else 6
		End
*/