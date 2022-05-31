
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 01/02/2016
-- Description: Append PartnerTable to add New Partners whom are on Relational
-- Mods: ZT 25/10/2018 - Added shoppersegment settings from Warehouse  
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Partner]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Partner',
	TableSchemaName = 'Relational',
	TableName = 'Partner',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


/**********************************************************************
************Find all partner IDs who have an offer Live****************
**********************************************************************/
IF OBJECT_ID ('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
SELECT	DISTINCT
	PartnerID
INTO #PartnerIDs
FROM SLC_Report.dbo.IronOffer io
INNER JOIN SLC_Report.dbo.IronOfferClub ioc
	ON io.ID = ioc.IronOfferID
INNER JOIN Relational.Club cl
	ON ioc.ClubID = cl.ClubID
	


/*********************************************************************
*****Only Add Partners we don't already have in the Partner Table*****
*********************************************************************/
INSERT INTO Relational.Partner
SELECT	p.PartnerID,
	par.Name as PartnerName
FROM #PartnerIDs p
INNER JOIN SLC_Report.dbo.Partner par
	ON p.PartnerID = par.ID
LEFT OUTER JOIN Relational.Partner qp
	ON p.PartnerID = qp.PartnerID
WHERE	qp.PartnerID IS NULL
ORDER BY Name


ALTER INDEX ALL ON Relational.Partner REBUILD



/******************************************************************		
		Create shoppersegment settings based on Warehouse 
******************************************************************/

Insert into nFI.Segmentation.PartnerSettings 
Select wh.PartnerID, wh.Lapsed, wh.Acquire, 1 RegisteredAtLeast, wh.StartDate, NULL EndDate, 0 CtrlGroup, 0 AutomaticRun
From Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings wh
left outer join  nFI.Segmentation.PartnerSettings n
	on wh.PartnerID = n.PartnerID
where n.PartnerID is null


/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Partner' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Partner' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.Partner)
WHERE	StoredProcedureName = 'WarehouseLoad_Partner' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Partner' 
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

TRUNCATE TABLE Staging.JobLog_Temp


END


