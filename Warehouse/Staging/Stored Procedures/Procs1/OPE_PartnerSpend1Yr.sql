/*
		Author:			Stuart Barnley
		Date Written:	11/02/2015

		Purpose:		This produces a table called 'Staging.PartnerSpend1Yr' which is populated
						with spend in the last year for all Partners in the 'Relational.Partner'
						table


*/

CREATE Procedure [Staging].[OPE_PartnerSpend1Yr]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'OPE_PartnerSpend1Yr',
	TableSchemaName = 'Staging',
	TableName = 'PartnerSpend1Yr',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

/*--------------------------------------------------------------------------------------------------
-----------------------------Create list of BrandIDs from Partner Table-----------------------------
----------------------------------------------------------------------------------------------------*/

if object_id('tempdb..#Brands') is not null drop table #Brands
select	p.PartnerID,
		p.BrandID,
		ROW_NUMBER() OVER(ORDER BY BrandID ASC) AS RowNo
Into #Brands
from Relational.Partner as p  with (nolock)
Where BrandID is not null

/*--------------------------------------------------------------------------------------------------
-------------------------Create Staging.PartnerSpend1Yr Table of 12mth spend------------------------
----------------------------------------------------------------------------------------------------*/
Declare @RowNo int, @MaxRowNo int, @Rows int,@RowEnd int
Set @RowNo = 1
Set @Rows = 5
Set @MaxRowNo = (Select Max(RowNo) from #Brands)

if object_id('tempdb..#CCs') is not null drop table #CCs
Create Table #CCs (PartnerID int, BrandID int, ConsumerCombinationID int)

if object_id('Staging.PartnerSpend1Yr') is not null drop table Staging.PartnerSpend1Yr
Create Table Staging.PartnerSpend1Yr (PartnerID int, BrandID int, YrlySpend Money,Trans int,Customers int)


While @RowNo <= @MaxRowNo
Begin
	
	---------------List of Consumer IDs per Brand---------------
	Set @RowEnd = @RowNo+(@Rows-1)
	Insert Into #CCs
	Select	b.PartnerID,
			b.BrandID,
			cc.ConsumerCombinationID 
	From Relational.ConsumerCombination as cc  with (nolock)
	inner join #Brands as b
		on cc.BrandID = b.BrandID
	Where b.RowNo Between @RowNo and @RowEnd
	
	---------------Transactional Spend per Brand---------------
	
	Insert Into Staging.PartnerSpend1Yr
	Select	c.PartnerID,
			c.BrandID,
			Sum(ct.Amount) as YrlySpend,
			Count(*) as Trans,
			Count(Distinct CINID) as Customers
	from #CCs as c  with (nolock)
	inner join Relational.ConsumerTransaction as ct with (nolock)
		on c.ConsumerCombinationID = ct.ConsumerCombinationID
	Where	TranDate >= Dateadd(Month,-6,Cast(getdate() as date)) and 
			TranDate < Cast(Getdate() as date)
	Group By c.PartnerID,c.BrandID

	Truncate table #CCs

	Set @RowNo = @RowEnd+1
End

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE  staging.JobLog_Temp
SET	EndDate = GETDATE()
WHERE	StoredProcedureName = 'OPE_PartnerSpend1Yr' and
	TableSchemaName = 'Staging' and
	TableName = 'PartnerSpend1Yr' and
	EndDate is null
		
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE  staging.JobLog_Temp
SET	TableRowCount = (Select COUNT(*) from Warehouse.Staging.PartnerSpend1Yr)
WHERE	StoredProcedureName = 'OPE_PartnerSpend1Yr' and
	TableSchemaName = 'Staging' and
	TableName = 'PartnerSpend1Yr' and
	TableRowCount IS NULL


INSERT INTO staging.JobLog
SELECT	[StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp