/*

	Author:		Stuart Barnley

	Date:		16the September 2016

	Purpose:	This stored procedure is used to find the campaign keys for the latest MyRewards email
				send and update the warehouse.

	Parameters:	@Update - if this is set to "0" it displays what it believes is the correct information,
						  whereas if "1" it updates the Relational.CampaignLionSendIDs table and displays
						  the update.
*/

CREATE PROCEDURE [WHB].[Emails_SmartFocusCampaignKey_UpdateorRead] (@Update bit)
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*---------------------------------------------------------------------------*/
	-------------------Produce List of new Campaigns to be added-------------------
	/*---------------------------------------------------------------------------*/

	IF OBJECT_ID('tempdb..#NewRows') IS NOT NULL DROP TABLE #NewRows
	Select  e.CampaignKey,
			LionSendID = Cast(SUBSTRING(CampaignName, PATINDEX('%LSID%', CampaignName) + 4, 3) as int),
			EmailType = 'H',
			Reference = Cast(Round(Cast(Datediff(day,'2016-07-22',SendDate) as real)/7,0,0)+236 as varchar(4))+'H',
			[HardCoded_OfferFrom] = Cast(NULL as int),
			[HardCoded_OfferTo] = Cast(NULL as int),
			[EmailName] = Cast(NULL as varchar(100)),
			ClubID = Case
						When CampaignName Like '%NatWest%' then 132
						When CampaignName Like '%NWC%' then 132
						When CampaignName Like '%NWP%' then 132
						Else 138
						End,
			TrueSolus = 0
	INTO #NewRows
	FROM [SLC_Report].[dbo].[EmailCampaign] e
	WHERE CampaignName LIKE '%Newsletter%LSID[0-9][0-9][0-9]%'
	AND CampaignName NOT LIKE 'TEST%'
	AND SendDate > '2016-07-22'
	AND NOT EXISTS (SELECT 1
					FROM [Relational].[CampaignLionSendIDs] cls
					WHERE e.CampaignKey = cls.CampaignKey)


	---------------------------------------

	If @Update = 0
	Begin
			/*---------------------------------------------------------------------------*/
			-------------------------------Review List-------------------------------------
			/*---------------------------------------------------------------------------*/

			Select * 
			from #NewRows as a
			inner join slc_report.dbo.EmailCampaign as EC with (nolock)
				on a.CampaignKey = EC.CampaignKey

	End

	--------------------------------------

	If @Update = 1
	Begin
			/*---------------------------------------------------------------------------*/
			-------------------------------Final Insert------------------------------------
			/*---------------------------------------------------------------------------*/
			INSERT INTO Relational.CampaignLionSendIDs
			SELECT	*
			FROM #NewRows

			/*---------------------------------------------------------------------------*/
			-------------------------------Final Checking--------------------------------
			/*---------------------------------------------------------------------------*/
			SELECT	top 25 *
			FROM Relational.CampaignLionSendIDs cls with (nolock)
			INNER JOIN SLC_Report.dbo.EmailCampaign as ec with (nolock)
				  ON cls.CampaignKey = ec.CampaignKey
			ORDER BY LionSendID Desc

			------------------------------------------------------------------------------
			--------------------------------------Drop tables-----------------------------
			------------------------------------------------------------------------------
	End 

	Drop table #NewRows

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