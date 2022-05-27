

/*
Author:		Suraj Chahal	
Date:		23rd May 2013
Purpose:	Load Email data in Warehouse using Stored Procedure.
Notes:		Includes logging of load time and rows copied

dbo.EmailEventCode		--lookup for Event Code
dbo.EmailEvent			--individual email events (Send, Open, Bounce etc)
dbo.EmailCampaign		--Represents an email broadcast

Update:		This version is being amended for use as a stored procedure and to be ultimately automated.
			27-12-2013 Stuart Barnley this was amended to change the WHILE condition for the emailevent
									  loading loop to avoid infinite loop problems. I also added NOLOCKS
			20-02-2014 SB - Removing reference to Warehouse
			10/09/2014 SC - Changed Indexing
*/
CREATE PROCEDURE [WHB].[Emails_SmartFocusEmailData_V1_6]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM Relational.EmailEvent)

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

insert into staging.JobLog_Temp
Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Relational',
		TableName = 'EmailEvent',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

/*--------------------------------------------------------------------------------------------------
----------------------Incrementally Build Email Event Table in Relational---------------------------
----------------------------------------------------------------------------------------------------*/

/*	Filter out records for customers who are not in CashBackPlus
	Also there is duplication introduced by the download process (there are some duplicated 
	combinations of Date, FanID, CampaignKey, EmailEventCodeID)
	There are no duplicated IDs
*/	
ALTER INDEX IDX_FanID ON Relational.EmailEvent DISABLE
ALTER INDEX IDX_Camp ON Relational.EmailEvent DISABLE


DECLARE @StartRow BIGINT,@SLCMaxRow BigInt,@ChunkSize INT
SET @StartRow = (SELECT MAX(EventID) from Relational.EmailEvent with (NoLock))
Set @SLCMaxRow = (Select Max(ID) 
				  from slc_report.dbo.EmailEvent as EE with (NoLock)
				  inner join relational.customer as c with (NoLock)
						on EE.FanID = c.FanID)
SET @ChunkSize = 250000

WHILE @SLCMaxRow > @StartRow
BEGIN

INSERT INTO Relational.EmailEvent		
SELECT TOP	(@ChunkSize) 
		MIN(ee.ID) as EventID, --Take the lowest ID. This is arbitrary, but is just needed as a unique key 
		ee.Date	as EventDateTime, --The date field is actually a datetime field
		CAST(ee.Date AS DATE) as EventDate, --cast as Date as this may be useful for some comparisons
		ee.FanID,
		c.CompositeID,
		ee.CampaignKey,
		ee.EmailEventCodeID
FROM slc_report.dbo.EmailEvent ee with (NoLock)
INNER JOIN Relational.Customer c with (NoLock)
	ON ee.FanID = c.FanID
WHERE ee.ID > @StartRow 
GROUP BY ee.Date, ee.FanID, c.CompositeID, ee.CampaignKey, ee.EmailEventCodeID
ORDER BY EventID
SET @StartRow = (Select MAX(EventID) FROM Relational.EmailEvent with (NoLock))
END


ALTER INDEX IDX_FanID ON Relational.EmailEvent REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
ALTER INDEX IDX_Camp ON Relational.EmailEvent REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

------------------------------------------------------------------------------------------------------
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEvent' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select (COUNT(*)-@RowCount) from Relational.EmailEvent))
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEvent' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Relational',
		TableName = 'EmailCampaign',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		ApendReload = 'R'	
/*--------------------------------------------------------------------------------------------------
----------------------Build Email Campaign Table in Staging-----------------------------------------
----------------------------------------------------------------------------------------------------*/
--restrict to only the campaigns that appear against customers in CashBackPlus	
--and sent since the launch of CBP.
Truncate table Relational.EmailCampaign	

SET IDENTITY_INSERT Relational.EmailCampaign ON

Insert into	Relational.EmailCampaign (ID,CampaignKey,EmailKey,CampaignName,[Subject],SendDateTime,SendDate	)
select	ec.ID as ID,
		ec.CampaignKey as CampaignKey,
		ec.EmailKey as EmailKey,
		ec.CampaignName as CampaignName,
		ec.Subject as [Subject],
		ec.SendDate						as SendDateTime,
		cast(ec.SendDate as date)		as SendDate
from	slc_report.dbo.EmailCampaign ec
where	ec.CampaignKey in (select distinct CampaignKey from Relational.EmailEvent)
		and ec.SendDate >= '1 Jan 2012'	
order by 	ec.SendDate		

SET IDENTITY_INSERT Relational.EmailCampaign OFF
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailCampaign' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.EmailCampaign)
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailCampaign' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Relational',
		TableName = 'EmailEventCode',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'	
/*--------------------------------------------------------------------------------------------------
----------------------Build Email Event Type in Staging---------------------------------------------
----------------------------------------------------------------------------------------------------*/
--NB. 'Used' bit flag doesn't completely agree with the the EventCodes that appear in the EmailEvent table
--Therefore not pulled through here until understood better.
Truncate table Relational.EmailEventCode

Insert into	Relational.EmailEventCode	

select	ID			as EmailEventCodeID,
		Name		as EmailEventDesc
		--Used
from	slc_report.dbo.EmailEventCode
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEventCode' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.EmailEventCode)
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Relational' and
		TableName = 'EmailEventCode' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

Truncate Table staging.JobLog_Temp

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run


END