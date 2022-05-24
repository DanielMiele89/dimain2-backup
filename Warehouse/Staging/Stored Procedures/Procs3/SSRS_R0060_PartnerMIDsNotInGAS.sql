/*
		Author:			Stuart Barnley

		Date:			25th February 2016

		Purpose:		To select all partners and pass them to Stored Procedure
						SSRS_R0060_PartnerMIDsNotInGAS_Per_Partner

		Update:			N/A
*/

CREATE Procedure [Staging].[SSRS_R0060_PartnerMIDsNotInGAS]
as

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0060_PartnerMIDsNotInGAS',
	TableSchemaName = 'Staging',
	TableName = 'R_0060_Outlet_NotinMIDS',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'R'

----------------------------------------------------------------------------------------
-----------------------------Generate List of Partners----------------------------------
----------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#P') IS NOT NULL DROP TABLE #P
SELECT	P.PartnerID,
	ROW_NUMBER() OVER(ORDER BY p.PartnerID Asc) AS RowNo
INTO #P
FROM Relational.Partner as p
Left Outer join Staging.R_0060_Partners_ToExclude as a
	on p.partnerid = a.PartnerID
Where	p.CurrentlyActive = 1 and
		a.PartnerID is null
----------------------------------------------------------------------------------------
-------------Call Per Partner Stored Procedure - looping for all partners---------------
----------------------------------------------------------------------------------------
DECLARE	@RowNo INT,
	@MaxRowNo INT,
	@PartnerID INT

SET @RowNo = 1
SET @MaxRowNo = (SELECT MAX(RowNo) FROM #P)
SELECT @RowNo,@MaxRowNo

TRUNCATE TABLE Staging.R_0060_Outlet_NotinMIDS

WHILE @RowNo <= @MaxRowNo
BEGIN
	SET	@PartnerID = (Select PartnerID from #P where RowNo = @RowNo)
	
		EXEC Staging.SSRS_R0060_PartnerMIDsNotInGAS_PerPartner @PartnerID
	
	SET	@RowNo = @RowNo+1
	
	SELECT @RowNo
END

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0060_PartnerMIDsNotInGAS' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0060_Outlet_NotinMIDS' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.R_0060_Outlet_NotinMIDS)
WHERE	StoredProcedureName = 'SSRS_R0060_PartnerMIDsNotInGAS'
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0060_Outlet_NotinMIDS' 
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp