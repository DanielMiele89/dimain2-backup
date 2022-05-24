-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__Customer_SchemeMembership_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'Customer_SchemeMembership', 'Started'

		-------------------------------------------------------------------------------
		-- LoyaltyAdditions_Customer_SchemeMembership_V1_1 ############################
		-------------------------------------------------------------------------------


		--Find each customers Scheme Membership type
		if object_id('tempdb..#SMT') is not null drop table #SMT
		Select	c.FanID,
				Case
					When c.CurrentlyActive = 0 then 8
					When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (2) then 1
					When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (0) then 3
					When dd.OnTrial = 1 then 3
					When cp.PaymentMethodsAvailableID in (0) then 4
					When cp.PaymentMethodsAvailableID in (1) then 5
					When cp.PaymentMethodsAvailableID in (2) then 2
					When cp.PaymentMethodsAvailableID in (3) then 4
					Else null
				End as SchemeMembershipTypeID,
				RegistrationDate,
				DeactivatedDate
		Into #SMT
		From [Staging].Customer c
		inner join [Derived].[Customer_PaymentMethodsAvailable] cp
			on c.FanID = cp.FanID 
			and cp.EndDate is null
		left join SLC_Report.[dbo].[FanSFDDailyUploadData_DirectDebit] dd
			on c.FanID = dd.FanID

		CREATE CLUSTERED INDEX cs_Stuff ON #SMT (FanID)


		UPDATE b
			SET SchemeMembershipTypeID = 
					(Case
						When b.SchemeMembershipTypeID in (1,2,5) then 6
						When b.SchemeMembershipTypeID in (3,4) then 7
						Else b.SchemeMembershipTypeID
						End)
				
		FROM #SMT b
		INNER JOIN Staging.SLC_Report_DailyLoad_Phase2DataFields a
			on b.FanID = a.FanID
		WHERE a.LoyaltyAccount = 1 
			and b.SchemeMembershipTypeID in (1,2,3,4,5)


		--Close off existing records in Relational.Customer_SchemeMembership
		UPDATE cs
			SET EndDate = Case
							When DeactivatedDate = Cast(getdate() as date) then Dateadd(day,-1,CAST(getdate() as Date))
							Else Dateadd(day,-2,CAST(getdate() as Date))
						End
		FROM Derived.Customer_SchemeMembership as cs	
		INNER JOIN #SMT as smt	
			on smt.FanID = cs.FanID
		WHERE smt.SchemeMembershipTypeID <> cs.SchemeMembershipTypeID 
			and cs.EndDate is null


		--Create new entries in Relational.Customer_SchemeMembership-----------------------
		INSERT INTO Derived.Customer_SchemeMembership
		SELECT	smt.FanID,
				smt.SchemeMembershipTypeID,
				Case
					When RegistrationDate = CAST(getdate() as Date) then CAST(getdate() as Date)
					Else dateadd(day,-1,CAST(getdate() as Date))
				End as StartDate,
				CAST(NULL as Date) as EndDate
		FROM #SMT as smt
		WHERE NOT EXISTS (SELECT 1 FROM Derived.Customer_SchemeMembership as cs
			WHERE smt.FanID = cs.FanID 
				and smt.SchemeMembershipTypeID = cs.SchemeMembershipTypeID 
				and cs.EndDate is null)

	EXEC [Monitor].[ProcessLog_Insert] 'Customer_SchemeMembership', 'Finished'


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