/******************************************************************************
-- Author:		Jason Shipp
-- Create date: 01/06/2017
-- Description:	Populate MI.ElectronicRedemptions_And_Stock table, and trigger eVoucher Usage Report subscription
-- Alterations:

-- Jason Shipp
	-- Added execution triggers for Cycle Live Offers Report: populate MI.Cycle_Live_OffersCardholders table and trigger report subscription 

-- Jason Shipp 09/08/2018
	-- Updated logic to check when to trigger MI.Cycle_Live_OffersCardholders_Populate stored procedure

-- Jason Shipp 02/04/2018
	-- Added trigger for Engagement Report load and email subscription
	-- Added trigger for MTR Transaction and Invoice data subscription

******************************************************************************/
CREATE PROCEDURE [MI].[ElectronicRedemptionsReport_ProcessAndSend]

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
		Select	StoredProcedureName = 'ElectronicRedemptionsReport_ProcessAndSend',
				TableSchemaName = 'MI',
				TableName = '',
				StartDate = GETDATE(),
				EndDate = null,
				TableRowCount  = null,
				AppendReload = 'U'

		-------------------------------------------------------------------------------------------------------------------

			SET NOCOUNT ON;

			DECLARE @DateName VARCHAR(50) = DATENAME(dw, GETDATE());
			DECLARE @Today DATE = CAST(GETDATE() AS DATE)

			IF @DateName != 'Saturday' AND @DateName != 'Sunday'
			BEGIN
				EXEC [MI].[ElectronicRedemptions_And_Stock_Populate]
				EXEC [MI].[Card_Redemptions_Populate]
				EXEC msdb.dbo.sp_start_job '51C630AA-68D8-4325-945E-E85397857848' -- eVoucher Usage Report
			END
			
			IF
			--CAST((DATEDIFF(day, '2016-12-08', (DATEADD(day, -1, @Today)))) AS FLOAT)/28 = (DATEDIFF(day, '2016-12-08', (DATEADD(day, -1, @Today))))/28
			-- 2016-12-08 is the start date of a random cycle in the past
			-- Dividing by 28 converts to number of campaign cycles	
			-- Checks if the number of cycles as of yesterday is a whole number. If true, today is the start of a new cycle, and the report is generated
			-- @Today is offset by one day, so the report delivery is delayed by one extra day
			(DATEDIFF(day, '2016-12-08', @Today)-1)%28 = 0 -- Same as above, but uses Modulus operator to check for whole number
			BEGIN
				EXECUTE [MI].[Cycle_Live_OffersCardholders_Populate]
				EXECUTE msdb.dbo.sp_start_job '8B8BA9F4-D619-49A9-B648-F697CD96A766' -- Campaign Cycle Live Offers Report
			END

			DECLARE @WorkingDaysIntoMonth date = (SELECT MI.AddWorkingDays(
				DATEADD(day, -(DATEPART(day, @Today)-1), @Today)
				, 4
			));

			DECLARE @WorkingDaysIntoMonthNotMonTue date = (
				SELECT CASE DATENAME(dw, @WorkingDaysIntoMonth)
					WHEN 'Monday' THEN DATEADD(day, 2, @WorkingDaysIntoMonth)
					WHEN 'Tuesday' THEN DATEADD(day, 1, @WorkingDaysIntoMonth)
					ELSE @WorkingDaysIntoMonth
				END
			);

			IF @Today = @WorkingDaysIntoMonthNotMonTue
			BEGIN
				EXEC Warehouse.Staging.RedemEarnCommReport_Load
				EXEC msdb.dbo.sp_start_job '948B5468-1EF2-483F-8D17-B7D1B17510EF' -- RedemEarnCommReport (Engagement Report)
			END

			DECLARE @WorkingDaysIntoMonth2 date = (SELECT MI.AddWorkingDays(
				DATEADD(day, -(DATEPART(day, @Today)-1), @Today)
				, 6
			));

			IF @Today = @WorkingDaysIntoMonth2
			BEGIN
				EXEC msdb.dbo.sp_start_job '59E3EA7D-DFD3-40F8-8B48-5E02FEF5099A' -- TransactionInvoiceSummary_MTR
			END

		/*--------------------------------------------------------------------------------------------------
		---------------------------Update entry in JobLog Table with End Date-------------------------------
		----------------------------------------------------------------------------------------------------*/
		Update  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		where	StoredProcedureName = 'ElectronicRedemptionsReport_ProcessAndSend' and
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