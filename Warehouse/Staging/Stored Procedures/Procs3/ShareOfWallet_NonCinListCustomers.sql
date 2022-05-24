/*
	Author:			Stuart Barnley
	Date:			10-04-2014

	Description:	This stored procedure has been created to make sure those
					customers who activate with no entry in CINList get	an 
					entry per partner in the SoW_Members tables.

					This avoids these people being ignored for offer selections
					because they have no transactional data ever.

					This was a flaw in HTM.

					This can be added to the ETL and run daily to keep all 
					customers available for selection.
*/

CREATE Procedure [Staging].[ShareOfWallet_NonCinListCustomers]
As

/*----------------------------------------------------------------------
-------------------Write entry to JobLog_Temp Table---------------------
------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select		StoredProcedureName = 'ShareOfWallet_NonCinListCustomers',
		TableSchemaName = 'Relational',
		TableName = 'ShareOfWallet_Members',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

/*-----------------------------------------------------------------------
--------------------Find those people without CinIDs---------------------
-----------------------------------------------------------------------*/
/* Some customers do not have any transactions in ConsumerTrans and are 
   therefore not picked up by the SoW process--------------------------*/

if object_id('tempdb..#themissingfew') is not null drop table #themissingfew
SELECT DISTINCT FanID
INTO   #themissingfew
FROM   Relational.Customer AS c
       LEFT OUTER JOIN Relational.CINList AS cl
                    ON c.SourceUID = cl.CIN
WHERE  CurrentlyActive = 1
       AND cl.CINID IS NULL 

/*-----------------------------------------------------------------------
--------------------Find partners to add records against-----------------
-----------------------------------------------------------------------*/
--We need a list of all the partners being headroomed
if object_id('tempdb..#Partners') is not null drop table #Partners
SELECT DISTINCT Partnerid
INTO   #Partners
FROM   Relational.ShareOfWallet_Members
WHERE  EndDate IS NULL and PartnerID >= 1000

/*-----------------------------------------------------------------------
--------------------------Partners already SoW'ed------------------------
-----------------------------------------------------------------------*/
--We need a list of those already populated
if object_id('tempdb..#AlreadyDone') is not null drop table #AlreadyDone
SELECT a.FanID,
       p.PartnerID
INTO   #AlreadyDone
FROM   #themissingfew AS a
       INNER JOIN Relational.ShareOfWallet_Members AS m
               ON a.FanID = m.FanID
       INNER JOIN #Partners AS p
               ON m.PartnerID = p.PartnerID 
/*-----------------------------------------------------------------------
-----------------Create entries to be added SoW_Members------------------
-----------------------------------------------------------------------*/
/*For each missing entry create a row to be added to SoW members tables with
  todays date as the StartDate and NULL as EndDate*/

if object_id('tempdb..#SoW_tobeadded') is not null drop table #SoW_tobeadded
SELECT a.FanID				   AS FanID,
       10                      AS HTMID,
       a.PartnerID			   AS PartnerID,
       Cast(Getdate() AS DATE) AS StartDate,
       Cast(NULL AS DATE)      AS EndDate
INTO   #sow_tobeadded
FROM   (SELECT tmf.FanID,
               p.PartnerID
        FROM   #themissingfew AS tmf,
               #partners AS p) AS a
       LEFT OUTER JOIN #alreadydone AS ad
                    ON a.FanID = ad.FanID
                       AND a.PartnerID = ad.PartnerID
WHERE  ad.FanID IS NULL

/*-----------------------------------------------------------------------
-----------------------Insert into SoW_Members table---------------------
-----------------------------------------------------------------------*/
Insert into Relational.ShareOfWallet_Members
Select * from #sow_tobeadded

/*--------------------------------------------------------------------------------------------------
-------------------------Update entry in JobLog_Temp Table with End Date----------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'ShareOfWallet_NonCinListCustomers' and
		TableSchemaName = 'Relational' and
		TableName = 'ShareOfWallet_Members' and
		EndDate is null
		
/*--------------------------------------------------------------------------------------------------
-------------------------Update entry in JobLog_Temp Table with Row Count---------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set	TableRowCount = (Select COUNT(*) from #sow_tobeadded)
where	StoredProcedureName = 'ShareOfWallet_NonCinListCustomers' and
		TableSchemaName = 'Relational' and
		TableName = 'ShareOfWallet_Members' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
---------------------------------------Add entry to JobLog Table------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Warehouse.staging.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from Warehouse.staging.JobLog_Temp

TRUNCATE TABLE Warehouse.staging.JobLog_Temp