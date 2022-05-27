/******************************************************************************
-- Author:		Jason Shipp
-- Create date: 01/06/2017
-- Description:	Populate MI.ElectronicRedemptions_And_Stock table, and trigger eVoucher Usage Report subscription
-- Alterations:

-- Jason Shipp
	-- Added execution triggers for Cycle Live Offers Report: populate MI.Cycle_Live_OffersCardholders table and trigger report subscription 

-- Jason Shipp 09/08/2018
	-- Updated logic to check when to trigger MI.Cycle_Live_OffersCardholders_Populate stored procedure

-- Jason Shipp 02/04/2019
	-- Added trigger for Engagement Report load and email subscription
	-- Added trigger for MTR Transaction and Invoice data subscription

-- Jason Shipp 11/04/2019
	-- Added triggers for Sky Direct Debit Reports' load and email subscriptions

******************************************************************************/
CREATE PROCEDURE [WHB].[Redemptions_ElectronicRedemptionsReport_ProcessAndSend]

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
				TableSchemaName = 'MI',
				TableName = '',
				StartDate = GETDATE(),
				EndDate = null,
				TableRowCount  = null,
				AppendReload = 'U'

		-------------------------------------------------------------------------------------------------------------------

		SET NOCOUNT ON;

		DECLARE @Today DATE = CAST(GETDATE() AS DATE);
		DECLARE @DateName VARCHAR(50) = DATENAME(dw, @Today);	

		IF @DateName != 'Saturday' AND @DateName != 'Sunday'
		BEGIN
			EXEC [WHB].[Redemptions_ElectronicRedemptions_And_Stock_Populate]
			EXEC [WHB].[Redemptions_Card_Redemptions_Populate]
			EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'BDB5DD45-365C-427C-8A03-A95455BB0F14' -- eVoucher Usage Report
			
			--	EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'DirectDebitFlashReports' -- Trigger the flash transaction and incremental direct debit report ETLs and email subscriptions
		END

		IF @DateName = 'Tuesday' OR DATEPART(day, @Today) = 2
		BEGIN
			EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'FC387E8D-53FD-4F0D-BE42-99C9742825C1' -- RedemptionItemActualsByMonth
		END

		IF DATEPART(day, @Today) = 10
		BEGIN
			EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'E2CC3A47-5787-4167-A1B8-AF4AE3681ADA' -- DirectDebitOIN
		END
	
		--IF	
		--CAST((DATEDIFF(day, '2016-12-08', (DATEADD(day, -1, @Today)))) AS FLOAT)/28 = (DATEDIFF(day, '2016-12-08', (DATEADD(day, -1, @Today))))/28
		-- 2016-12-08 is the start date of a random cycle in the past
		-- Dividing by 28 converts to number of campaign cycles	
		-- Checks if the number of cycles as of yesterday is a whole number. If true, today is the start of a new cycle, and the report is generated
		---- @Today is offset by one day, so the report delivery is delayed by one extra day
		--(DATEDIFF(day, '2016-12-08', @Today)-1)%28 = 0 -- Same as above, but uses Modulus operator to check for whole number
		--BEGIN
		--	EXECUTE [WHB].[Redemptions_Cycle_Live_OffersCardholders_Populate]
		--	EXECUTE [DIMAIN].[msdb].[dbo].[sp_start_job] '8B8BA9F4-D619-49A9-B648-F697CD96A766' -- Campaign Cycle Live Offers Report
		--END

		DECLARE @WorkingDaysIntoMonth date = (SELECT MI.AddWorkingDays(
			DATEADD(day, -(DATEPART(day, @Today)-1), @Today)
			, 4
		));

		DECLARE @WorkingDaysIntoMonthNotMonTue date = ( -- Adjust trigger so it only falls on a Tues or Wed (server less likely to be busy)
			SELECT CASE DATENAME(dw, @WorkingDaysIntoMonth)
				WHEN 'Monday' THEN DATEADD(day, 2, @WorkingDaysIntoMonth)
				WHEN 'Tuesday' THEN DATEADD(day, 1, @WorkingDaysIntoMonth)
				--WHEN 'Friday' THEN DATEADD(day, 5, @WorkingDaysIntoMonth)
				ELSE @WorkingDaysIntoMonth
			END
		);

		IF @Today = @WorkingDaysIntoMonthNotMonTue
		BEGIN
			EXEC [msdb].[dbo].[sp_start_job] 'RBSEngagementReports' -- RedemEarnCommReport and RBSPerformanceKPIReport report data loads and email subscriptions
		END

		DECLARE @WorkingDaysIntoMonth2 date = (SELECT MI.AddWorkingDays(
			DATEADD(day, -(DATEPART(day, @Today)-1), @Today)
			, 6
		));

		IF @Today = @WorkingDaysIntoMonth2
		BEGIN
			EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] '59E3EA7D-DFD3-40F8-8B48-5E02FEF5099A' -- TransactionInvoiceSummary_MTR
		END

		DECLARE @FirstMondayOfMonth date = DATEADD(
			week,
			DATEDIFF(week, 0, DATEADD(day, 6-DATEPART(day, @Today), @Today))
			, 0
		);

		IF @Today = @FirstMondayOfMonth
		BEGIN
			EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'F35B3297-D965-4D1F-87F4-FABF6BB50ACA' -- MyRewardsAccountSummary
		END

		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with End Date-------------------------------
		----------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'MI' and
				TableName = '' and
				EndDate is null

		Insert into staging.JobLog
		select [StoredProcedureName],
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

END
