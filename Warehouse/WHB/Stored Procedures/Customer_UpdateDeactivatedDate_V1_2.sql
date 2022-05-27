﻿/*	Author:			Stuart Barnley
	Description:	Created to update Customer table based on a selection of deactivation methods

	Update:			20-02-2014 SB - Updated to remove references Warehouse
*/
CREATE PROCEDURE [WHB].[Customer_UpdateDeactivatedDate_V1_2]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Staging',
		TableName = 'Customer',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'C'

---------------------------------------------------------------------------------------
-----------Find those customers who are deactivated with no DeactivatedDate------------
---------------------------------------------------------------------------------------
/*DeactivatedDate is populated off of a table end produces based on an assessment of the
  changelog, therefore I am finding dates for those catered for by this*/

select FanID,AgreedTCsDate as ActivatedDate
Into #DeactivatedCustomers 
from Staging.customer as c
where	status = 0 and 
		deactivateddate is null
---------------------------------------------------------------------------------------
-----------------Find comment that indicates the Fan was Deactivated-------------------
---------------------------------------------------------------------------------------
/*This comment is normally generated by an overnight process checking valid Pans and 
  Fans etc*/
Select c.FanID,Max([Date]) as Deact_Date
Into #Comm_Deact
from slc_report.dbo.comments  as c
inner join #DeactivatedCustomers as dc
	on	c.FanID = dc.FanID
Where	c.Comment Like  'Fan Deactivated%' and
		c.[Date] >= DC.ActivatedDate
Group by c.FanID
---------------------------------------------------------------------------------------
----------------------Find Date from DeactivatedCustomer table-------------------------
---------------------------------------------------------------------------------------
/*We started populating this table a while ago (July 2012) before the changelog was 
  even conceived.Every week it stored all the activated customers with Status zero and 
  the date */
Select	Dc.FanID, 
		Min(DataDate) as Deact_Date
into #DeactTable
from #DeactivatedCustomers as DC
inner join staging.DeactivatedCustomers as c
	on dc.FanID = c.FanID
Left Outer join #Comm_Deact as cd
	on dc.FanID = cd.FanID
Where	cd.FanID is null
Group by DC.FanID
	Having Min(DataDate) > 'Jul 17, 2012' -- ignore those from first week.
---------------------------------------------------------------------------------------
----------------------Find List of those still without deactivateddate-----------------
---------------------------------------------------------------------------------------
Select dc.FanID,dc.ActivatedDate
into #D
from #DeactivatedCustomers as dc
Left Outer join #Comm_Deact as cd
	on dc.FanID = cd.FanID
Left Outer join #DeactTable as d
	on dc.FanID = d.FanID
Where cd.fanid is null and d.fanid is null

---------------------------------------------------------------------------------------
----------------------Find other Comment entries to use for date-----------------------
---------------------------------------------------------------------------------------

Select c.ObjectID,Max([Date]) as Deact_Date
		
Into #Comm_Deact2
from slc_report.dbo.comments  as c
inner join #DeactivatedCustomers as dc
	on	c.ObjectID = dc.FanID
Left Outer Join
	(Select * 
	 from #Comm_Deact
	 union all
	 Select * 
	 from #DeactTable
	 )as a
	on dc.FanID = a.fanid
Where	(c.Comment Like '%Opt_Out%' or
		 c.Comment Like '%Account_Close%' or
		 c.Comment Like '%Close_Account%' or
		 c.Comment like '%Disabled%' or
		 c.Comment like '%Deceased%' or
		 c.Comment like '%Died%' or
		 c.Comment like '%Removed_Scheme%' or
		 c.Comment like '%Pan Deactivated%'
		 ) and
		c.[Date] >= DC.ActivatedDate and
		a.FanID is null
Group by c.ObjectID

---------------------------------------------------------------------------------------
-------------------------Create a table of Deac dates----------------------------------
---------------------------------------------------------------------------------------
/*Where no other date could be found we put in the Activation Date*/
Select Dc.* ,
		Case
			When a.Deact_Date IS null then dc.ActivatedDate
			Else a.Deact_Date
		End as DDate
Into #Deactivations
from #DeactivatedCustomers as dc
left outer join
	(Select * 
	 from #Comm_Deact
	 union all
	 Select * 
	 from #DeactTable
	 union all
	 Select * 
	 from #Comm_Deact2) as a
	on dc.FanID = a.fanid
---------------------------------------------------------------------------------------
--------------------------------Update Customer Table----------------------------------
---------------------------------------------------------------------------------------
Update Staging.Customer
Set DeactivatedDate = DDate
From Staging.Customer as c
Inner join #Deactivations as D
	on C.FanID = D.FanID
Where	C.AgreedTCsDate is not null and
		c.Status = 0

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Staging' and
		TableName = 'Customer' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from #Deactivations)
where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Staging' and
		TableName = 'Customer' and
		TableRowCount is null

Insert into staging.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

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

End