CREATE Procedure [Lion].[LionSendTracking_UpdateEmailEvents]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	DROP INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers]

	-- update campaign key info

		If Object_ID('tempdb..#EmailCampaign') Is Not Null Drop Table #EmailCampaign
		Select ec.CampaignKey
			 , CampaignName
			 , SendDate
			 , Case
				When CampaignName Like '%NWC%' Or CampaignName Like '%NatWest%' Then 132
				When CampaignName Like '%NWP%' Or CampaignName Like '%NatWest%' Then 132
				When CampaignName Like '%RBSC%' Or CampaignName Like '%RBS%' Then 138
				When CampaignName Like '%RBSP%' Or CampaignName Like '%RBS%' Then 138
			   End as ClubID
			 , Case
				When CampaignName Like '%NWC%' Or CampaignName Like '%Core%' Then 0
				When CampaignName Like '%NWP%' Or CampaignName Like '%Private%' Then 1
				When CampaignName Like '%RBSC%' Or CampaignName Like '%Core%' Then 0
				When CampaignName Like '%RBSP%' Or CampaignName Like '%Private%' Then 1
			   End as IsLoyalty
			 , Case When PatIndex('%LSID%', CampaignName) > 0 Then Substring(CampaignName, PatIndex('%LSID%', CampaignName) + 4, 3) Else Null End as LionSendID
		Into #EmailCampaign
		From Relational.EmailCampaign ec
		Where CampaignName Like '%newsletter%'

		UPDATE #EmailCampaign
		SET LionSendID =	CASE
								WHEN CampaignName = 'NWC_SLHybridNewsletter_LSID729_14Jan2021_LIVE2' THEN 732
								WHEN CampaignName = 'NWC_SLHybridNewsletter_LSID729_14Jan2021' THEN 730
								
								WHEN CampaignName = 'NWC_GenericHybridNewsletter_LSID727_14Jan202' THEN 728
								WHEN CampaignName = 'NWP_GenericHybridNewsletter_LSID727_14Jan202' THEN 728
								WHEN CampaignName = 'RBSC_GenericHybridNewsletter_LSID727_14Jan202' THEN 728
								WHEN CampaignName = 'RBSP_GenericHybridNewsletter__LSID727_14Jan2021' THEN 728

								WHEN CampaignName = 'NWC_GenericHybridNewsletter_LSID731_28Jan2021' THEN 734
								WHEN CampaignName = 'NWP_GenericHybridNewsletter_LSID731_28Jan2021' THEN 734
								WHEN CampaignName = 'RBSC_GenericHybridNewsletter_LSID731_28Jan2021' THEN 734
								WHEN CampaignName = 'RBSP_GenericHybridNewsletter_LSID731_28Jan2021' THEN 734
								ELSE LionSendID
							END

		Update ls
		Set ls.CampaignKey = ec.CampaignKey
		From [Lion].[LionSend_Customers] ls
		Inner join #EmailCampaign ec
			on ls.LionSendID = ec.LionSendID
			and ls.IsLoyalty = ec.IsLoyalty
			and ls.ClubID = ec.ClubID
		Where ls.CampaignKey Is Null
	

	-- update sent & opened
	
		If Object_ID('tempdb..#EmailNotSent') Is Not Null Drop Table #EmailNotSent
		Select lsc.CampaignKey
			 , lsc.FanID
		Into #EmailNotSent
		From [Lion].[LionSend_Customers] lsc
		Where lsc.EmailSent = 0

		Create Clustered Index CIX_EmailNotSent_FanID On #EmailNotSent (CampaignKey, FanID)
	

		If Object_ID('tempdb..#EmailSent') Is Not Null Drop Table #EmailSent
		Select Distinct
			   ee.CampaignKey
			 , ee.FanID
		Into #EmailSent
		From #EmailNotSent ens
		Inner join Relational.EmailEvent ee
			on ens.FanID = ee.FanID
			and ens.CampaignKey = ee.CampaignKey

		Update lsc
		Set EmailSent = 1
		From [Lion].[LionSend_Customers] lsc
		Inner join #EmailSent es
			on lsc.CampaignKey = es.CampaignKey
			and lsc.FanID = es.FanID
		Where EmailSent = 0
	
		If Object_ID('tempdb..#EmailNotOpened') Is Not Null Drop Table #EmailNotOpened
		Select lsc.CampaignKey
			 , lsc.FanID
		Into #EmailNotOpened
		From [Lion].[LionSend_Customers] lsc
		Where lsc.EmailOpened = 0

		Create Clustered Index CIX_EmailNotOpened_CampaignKeyFanID On #EmailNotOpened (CampaignKey, FanID)


		If Object_ID('tempdb..#EmailOpens') Is Not Null Drop Table #EmailOpens
		Select ee.CampaignKey
			 , ee.FanID
			 , Min(EventDate) as EventDate
		Into #EmailOpens
		From #EmailNotOpened eno
		Inner join Relational.EmailEvent ee
			on eno.CampaignKey = ee.CampaignKey
			and eno.FanID = ee.FanID
		Where ee.EmailEventCodeID = 1301
		Group by ee.CampaignKey
			   , ee.FanID

		Update lsc
		Set EmailOpened = 1
		  , EmailOpenedDate = EventDate
		From [Lion].[LionSend_Customers] lsc
		Inner join #EmailOpens eo
			on lsc.CampaignKey = eo.CampaignKey
			and lsc.FanID = eo.FanID
		Where EmailOpened = 0
		

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [IsLoyalty], [EmailSent], [EmailOpened], [EmailOpenedDate])
 
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