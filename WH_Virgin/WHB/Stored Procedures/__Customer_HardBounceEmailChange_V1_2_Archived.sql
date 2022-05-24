
/*
	Author:			Stuart Barnley
	Date:			12-05-2014

	Description:	For customers that have changed their email address since 
					hard bouncing, this will reset the Hardbounce flag.
*/

CREATE PROCEDURE [WHB].[__Customer_HardBounceEmailChange_V1_2_Archived]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	-------------------------------------------------------------------------------
	--------------------------Find those who HardBounced---------------------------
	-------------------------------------------------------------------------------
	if object_id('tempdb..#HB') is not null drop table #HB
	select Distinct c.FanID
	into #HB
	from Derived.Customer as c
	where	c.Unsubscribed = 0 and 
			c.hardbounced = 1 and -- must have already hard bounced
			c.EmailStructureValid = 1 and  
			c.CurrentlyActive = 1 and -- must be active
			c.Marketablebyemail = 0 -- Currently not emailable

	-------------------------------------------------------------------------------
	-------------Find those who HardBounced - Latest Date of Bounce----------------
	-------------------------------------------------------------------------------
	if object_id('tempdb..#HBDate') is not null drop table #HBDate
	select Distinct	
			ee.FanID,
			Max(ee.EventDateTime) as HB_Date
	Into #HBDate
	from Derived.EmailEvent as ee with (nolock)
	inner join Derived.EmailEventCode as eec
		on ee.EmailEventCodeID = eec.EmailEventCodeID
	inner join #HB as hb
		on ee.FanID = hb.FanID
	Where ee.EmailEventCodeID = 702  -- Hard Bounce Event Code
	Group by ee.FanID
	-------------------------------------------------------------------------------
	------------------Find those who changed email after Bounce--------------------
	-------------------------------------------------------------------------------
	--Find the change of email address entry in the change log
	if object_id('tempdb..#NewEmail_Fans') is not null drop table #NewEmail_Fans
	Select Distinct #HBDate.[iad].FanID
	Into #NewEmail_Fans
	from Staging.InsightArchiveData as iad
	inner join #HBDate as h
		on	#HBDate.[iad].FanID = h.FanID and
			#HBDate.[typeID] = 2
	Where	#HBDate.[iad].[Date] > h.HB_Date and -- changelog entry must be after HardBounce
			[h].[HB_Date] >= 'Mar 01, 2014' /* This is so we don;t start emailing 
										 someone from to long ago*/
	-------------------------------------------------------------------------------
	----------------Change HardBounce Value then Marketablebyemail-----------------
	-------------------------------------------------------------------------------
	--Update Hardbounce and MarketbleByEmail for all those in the previously created list
	Update Derived.Customer
	Set [Derived].[Customer].[Hardbounced] = 0,
		[Derived].[Customer].[MarketableByEmail] = 1
	Where [Derived].[Customer].[FanID] in (Select #NewEmail_Fans.[FanID] from #NewEmail_Fans)

	/****************************************************************************************************/
	-------------------------------------------------------------------------------
	---------------------Find hardbounced group being re-engaged-------------------
	-------------------------------------------------------------------------------
	if object_id('tempdb..#HB_Re') is not null drop table #HB_Re
	Select	c.FanID,
			r.DateWS 
	Into #HB_Re
	from [Staging].[Customer_Hardbounced_Reengaged] as r -- Customers who are being reengaged with emails as part of RBSG plan
	inner join Derived.Customer as c
		on r.FanID = c.FanID
	Where DateWS <= Cast(getdate() as date) and
			c.Unsubscribed = 0 and 
			c.hardbounced = 1 and -- must have already hard bounced
			c.EmailStructureValid = 1 and  
			c.CurrentlyActive = 1 -- must be active		

	-------------------------------------------------------------------------------
	---------------------Find hardbounces for re-engaged group --------------------
	-------------------------------------------------------------------------------
	if object_id('tempdb..#HBDate2') is not null drop table #HBDate2
	select Distinct	
			ee.FanID,
			Max(ee.EventDateTime) as HB_Date
	Into #HBDate2
	from Derived.EmailEvent as ee with (nolock)
	inner join Derived.EmailEventCode as eec
		on ee.EmailEventCodeID = eec.EmailEventCodeID
	inner join #HB_Re as hb
		on ee.FanID = hb.FanID
	Where ee.EmailEventCodeID = 702  -- Hard Bounce Event Code
	Group by ee.FanID

	--Select * from #HBDate2
	--Order by HB_Date desc
	-------------------------------------------------------------------------------
	----------------------- Find re-Engaged not yet Re-Bounced --------------------
	-------------------------------------------------------------------------------
	if object_id('tempdb..#ReEngaged') is not null drop table #ReEngaged
	Select r. FanID 
	Into #ReEngaged
	from #HB_Re as r
	left outer Join #HBDate2 as h
		on	r.FanID = h.FanID and
			h.HB_Date > r.DateWS
	Where h.FanID is null

	-------------------------------------------------------------------------------
	----------------Change HardBounce Value then Marketablebyemail-----------------
	-------------------------------------------------------------------------------
	--Update Hardbounce and MarketbleByEmail for all those in the previously created list
	Update Derived.Customer
	Set [Derived].[Customer].[Hardbounced] = 0,
		[Derived].[Customer].[MarketableByEmail] = 1
	Where [Derived].[Customer].[FanID] in (Select #ReEngaged.[FanID] from #ReEngaged)




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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run