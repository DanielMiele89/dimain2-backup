
CREATE procedure [Prototype].[__g1_Archived] as


IF OBJECT_ID ('tempdb..##OfferMerged') IS NOT NULL DROP TABLE ##OfferMerged 
CREATE TABLE ##OfferMerged (
	CompositeID BIGINT,
	IronOfferID INT,
	ClientServicesRef varchar(10)
	)

/**************************************************************************
**************Looping mailable audience from selection tables**************
**************************************************************************/
DECLARE @StartRow INT,
	@Qry NVARCHAR(MAX),
	@TableName VARCHAR(100)

SET @StartRow = 1

WHILE @StartRow <= (SELECT MAX(TableID) FROM Warehouse.Relational.NominatedOfferMember_TableNames)
BEGIN

SET @TableName = (SELECT TableName FROM Warehouse.Relational.NominatedOfferMember_TableNames WHERE TableID = @StartRow)

SET @Qry = '

INSERT INTO ##OfferMerged
SELECT	CompositeID,
	OfferID as IronOfferID,
	ClientServicesRef
FROM '+ @TableName +'
WHERE Grp = ''Mail''
'
EXEC sp_ExecuteSQL @Qry
--EXEC (@QRY)

insert into #temp
select 'Step 2' Step , RowsReturned = (select  @@ROWCOUNT), [Error] = (select case when @@ROWCOUNT <= 0 then 'Yes' else 'No' end ), getdate() as [When]

SET @StartRow = @StartRow+1

END