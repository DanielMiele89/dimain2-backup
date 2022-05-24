/*
Author:		Stuart Barnley
Date:		03rd September 2013
Purpose:	Build a table to show who is email engaged
			
			Assess data daily and record changes
				
Update:		20-02-2014 - SB - Amended to remove all reference to Warehouse
					
*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_EmailEngagedV1_1]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @RowCount int
	Set @RowCount = (Select Count(*) From relational.Customer_EmailEngagement)
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_EmailEngagedV1_1',
			TableSchemaName = 'Relational',
			TableName = 'Customer_EmailEngagement',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
		
	------------------------------------------------------------------------------------
	----------------------------Pull out Activated Customers----------------------------
	------------------------------------------------------------------------------------
	--For those no longer Active or not MarketabelbyEmail then mark as EmailEngaged = 0
	select	Fanid,
			c.ActivatedDate,
			MarketablebyEmail,
			Case 
				When CurrentlyActive = 0 or MarketableByEmail = 0 then 0
				Else NULL
			End as EmailEngaged
	into #Cust_Emailable
	from relational.customer as c
	Where Activated = 1
	Order by EmailEngaged Desc
	--(183415 row(s) affected)
	------------------------------------------------------------------------------------
	-------------Pull a list of every email sent to the Activated Customer Base---------
	------------------------------------------------------------------------------------
	Select	ce.FanID,
			ec.CampaignKey,
			ec.SendDate,
			OpenDate,
			ROW_NUMBER() OVER(PARTITION BY ce.FanID ORDER BY SendDate DESC) AS RowNo
	Into #Emails
	from #Cust_Emailable as ce
	inner join slc_report.dbo.EmailActivity as ea ---Rolled up Email Event data
		on ce.FanID = ea.FanID
	inner join relational.EmailCampaign as ec
		on ea.EmailCampaignID = ec.ID
	inner join relational.CampaignLionSendIDs as cls --Find only email campaigns
		on ec.CampaignKey = cls.CampaignKey
	Where EmailEngaged is null and SendDate >= Dateadd(month,-6,cast(getdate() as date))
	--(1509317 row(s) affected)
	------------------------------------------------------------------------------------
	---------------------Work out who has been sent at least 4 emails-------------------
	------------------------------------------------------------------------------------
	Select Distinct FanID
	Into #Email_AtLeast4
	From #Emails
	Where RowNo >= 4
	--(66843 row(s) affected)
	------------------------------------------------------------------------------------
	---------------------Who has opened one of the last three emails--------------------
	------------------------------------------------------------------------------------
	--For those who have had at least 4 emails have they opened one of the last three

	select E.FanID,
		Sum(Case
				When OpenDate is not null then 1
				Else 0
			End) as Opens
	Into #EmailOpens
	from #Emails as E
	inner join #Email_AtLeast4 as e2
		on e.FanID = e2.FaniD
	Where E.RowNo <=3
	Group by E.FanID
	Having  Sum(Case
					When OpenDate is not null then 1
					Else 0
				End) > 0
	--(38316 row(s) affected)
	------------------------------------------------------------------------------------
	--------------------------Work out final engagement Score---------------------------
	------------------------------------------------------------------------------------
	Select  ce.Fanid,
			ce.MarketablebyEmail,
			--ce.EmailEngaged,
			Case
				When ce.EmailEngaged is not null then ce.EmailEngaged
				When ce.ActivatedDate < dateadd(month,-3,cast(getdate() as date)) and
						(a.LastSentDate is null or a.LastSentDate < dateadd(month,-2,cast(getdate() as date))) then 0 -- If activated over 3 months ago and email not opened in two then not engaged
				When eo.FanID is not null then 1 -- Received 4 and have opened an email in last 3 therefore engaged
				When e.FanID is null then 1 --Not had at least 4 emails in the last 6 months
				Else 0
			End as EmailEngaged
	into #EmailEngagement
	from #Cust_Emailable as ce
	left outer join #Email_AtLeast4 as e
		on ce.FanID = e.Fanid
	Left Outer join #EmailOpens as EO
		on ce.FanID = EO.FanID
	Left Outer join (Select FanID,Max(SendDate) as LastSentDate From #Emails Group by FanID) as a
		on ce.FanID = a.FanID
	--(183415 row(s) affected)
	------------------------------------------------------------------------------------
	---------------------Add New Email engagement rows to table-------------------------
	------------------------------------------------------------------------------------
	--When Engagement changes then new record added
	Insert into relational.Customer_EmailEngagement
	Select	EE.FanID,
			Cast(Getdate() as date) as StartDate,
			Cast(NULL as Date) as EndDate,
			EE.EmailEngaged
	from #EmailEngagement as EE
	Left Outer join relational.Customer_EmailEngagement as CEE
		on EE.FanID = CEE.FanID and EE.EmailEngaged = CEE.EmailEngaged and EndDate is null
	Where cee.FaniD is null
	------------------------------------------------------------------------------------
	------------------------------Update old row----------------------------------------
	------------------------------------------------------------------------------------
	--When new engagement record added previous record updated
	Update relational.Customer_EmailEngagement
	Set EndDate = dateadd(day,-1,cast(getdate() as date))
	From relational.Customer_EmailEngagement as cee
	inner join #EmailEngagement as EE
		on EE.FanID = CEE.FanID and EE.EmailEngaged <> CEE.EmailEngaged and EndDate is null

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_EmailEngagedV1_1' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_EmailEngagement' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from relational.Customer_EmailEngagement)-@RowCount
	where	StoredProcedureName = 'WarehouseLoad_Customer_EmailEngagedV1_1' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer_EmailEngagement' and
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
	truncate table staging.JobLog_Temp

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