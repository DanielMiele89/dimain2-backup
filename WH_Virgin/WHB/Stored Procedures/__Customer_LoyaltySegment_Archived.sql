-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__Customer_LoyaltySegment_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'Customer_LoyaltySegment', 'Started'

		-------------------------------------------------------------------------------
		-- LoyaltyAdditions_Customer_LoyaltySegment_V3 ##################################
		-------------------------------------------------------------------------------

		if object_id('tempdb..#CS') is not null drop table #CS;
		SELECT
			a.FanID,
			a.CustomerSegment,
			a.StartDate,
			a.RowNo
		INTO #CS
		FROM (	
			SELECT	
				c.FanID,
				Case
					When ica.Value is null then ''
					When ica.Value = 'V' then 'V'
					Else ''
				End as CustomerSegment,
				RegistrationDate as StartDate,
				ROW_NUMBER() OVER(PARTITION BY c.FanID ORDER BY ica.Value DESC) AS RowNo
			FROM [Staging].[Customer] c
			left join SLC_Report.dbo.IssuerCustomer as ic
				on c.SourceUID = ic.SourceUID
			Left join slc_report.dbo.issuer as i
				on ic.IssuerID = i.ID
			Left join slc_report.dbo.IssuerCustomerAttribute as ica
				on ic.ID = ica.IssuerCustomerID and
					ica.EndDate is null and ica.AttributeID = 1
			WHERE EndDate is null
		)  a
		WHERE a.RowNo = 1
		-- (4388857 rows affected)


		--Insert new segments----------------------------------------
		INSERT INTO Derived.Customer_LoyaltySegment
		SELECT	c.FanID,
				c.CustomerSegment,
				c.StartDate,
				NULL as EndDate
		FROM #CS c
		WHERE NOT EXISTS (
			SELECT 1 
			FROM Derived.Customer_LoyaltySegment as cs
			WHERE c.fanid = cs.fanid 
			and cs.enddate is null 
			and (Case
					When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
					Else c.CustomerSegment
					End) =
				(Case
						When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
						Else cs.CustomerSegment
					End)
		)


		--Update old segments----------------------------------------
		UPDATE cs
		SET [cs].[EndDate] = dateadd(day,-1,c.StartDate)
		FROM Derived.Customer_LoyaltySegment cs
		INNER JOIN #CS as c
			ON cs.fanid = c.fanid 
			and cs.enddate is null 
			and (Case
					When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
					Else c.CustomerSegment
					End) <>
				(Case
						When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
						Else cs.CustomerSegment
					End)



	EXEC [Monitor].[ProcessLog_Insert] 'Customer_LoyaltySegment', 'Finished'


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

END