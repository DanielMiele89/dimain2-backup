-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__Transactions_AdditionalCashbackAdjustment_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'Transactions_AdditionalCashbackAdjustment', 'Started'

		-------------------------------------------------------------------------------
		--EXEC WHB.AdditionalCashbackAward_Adjustments_V1_1 ###########################
		-------------------------------------------------------------------------------

		TRUNCATE TABLE Relational.AdditionalCashbackAdjustment
		INSERT INTO Derived.AdditionalCashbackAdjustment
		SELECT	t.FanID						as FanID,
				t.ProcessDate				as AddedDate,
				t.ClubCash* aca.Multiplier	as CashbackEarned,
				t.ActivationDays,
				aca.AdditionalCashbackAdjustmentTypeID
		FROM SLC_Report.dbo.Trans t 
		INNER JOIN ( -- Insert excludes Burn As You Earn, as these have an ItemID of 0 in the Warehouse.Relational.AdditionalCashbackAdjustmentType table
			SELECT aca.*,tt.Multiplier
			FROM Warehouse.Relational.AdditionalCashbackAdjustmentType aca
			INNER JOIN SLC_Report.dbo.TransactionType tt 
				on aca.TypeID = tt.ID
		) aca 
			on t.ItemID = aca.ItemID 
			and t.TypeID = aca.TypeID
			--and t.fanid = 1960606
		INNER JOIN Derived.Customer as c
			on t.FanID = c.FanID









		-------------------------------------------------------------------------------
		--EXEC WHB.AdditionalCashbackAward_Adjustment_AmazonRedemptions ###############
		-------------------------------------------------------------------------------

		--Find Transactions for Earn while you burn bonus-----------------------------
		IF object_id('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
		SELECT	t.TypeiD,
				t.FanID,
				t.ProcessDate,
				t.ClubCash* tt.Multiplier	as CashbackEarned,
				t.ActivationDays,
				t.ItemID
		INTO #Trans
		FROM SLC_Report.dbo.Trans t 
		INNER JOIN SLC_Report.dbo.TransactionType tt 
			on t.TypeID = tt.ID		
		INNER JOIN Derived.Customer c 
			on t.FanID = c.FanID
		WHERE TypeID in (26,27)
		-- (104991 rows affected) / 00:00:20

		CREATE CLUSTERED INDEX i_Trans_ItemID on #Trans (ItemID)



		INSERT INTO [Derived].[AdditionalCashbackAdjustment]
		SELECT	
			a.FanID,
			a.ProcessDate,
			a.CashbackEarned,
			a.ActivationDays,
			Case
				-- Amazon
				When b.ItemID = 7236 and a.TypeID = 26 then 77 
				When b.ItemID = 7238 and a.TypeID = 26 then 78
				When b.ItemID = 7240 and a.TypeID = 26 then 79
				When b.ItemID = 7236 and a.TypeID = 27 then 80
				When b.ItemID = 7238 and a.TypeID = 27 then 81
				When b.ItemID = 7240 and a.TypeID = 27 then 82
				-- M&S
				When b.ItemID = 7242 and a.TypeID = 26 then 83
				When b.ItemID = 7243 and a.TypeID = 26 then 84
				When b.ItemID = 7244 and a.TypeID = 26 then 85
				When b.ItemID = 7242 and a.TypeID = 27 then 86
				When b.ItemID = 7243 and a.TypeID = 27 then 87
				When b.ItemID = 7244 and a.TypeID = 27 then 88
				-- B&Q
				When b.ItemID = 7248 and a.TypeID = 26 then 95
				When b.ItemID = 7249 and a.TypeID = 26 then 96
				When b.ItemID = 7250 and a.TypeID = 26 then 97
				When b.ItemID = 7248 and a.TypeID = 27 then 98
				When b.ItemID = 7249 and a.TypeID = 27 then 99
				When b.ItemID = 7250 and a.TypeID = 27 then 100
				-- Argos
				When b.ItemID = 7256 and a.TypeID = 26 then 101
				When b.ItemID = 7257 and a.TypeID = 26 then 102
				When b.ItemID = 7258 and a.TypeID = 26 then 103
				When b.ItemID = 7256 and a.TypeID = 27 then 104
				When b.ItemID = 7257 and a.TypeID = 27 then 105
				When b.ItemID = 7258 and a.TypeID = 27 then 106
				-- John Lewis
				When b.ItemID = 7260 and a.TypeID = 26 then 107
				When b.ItemID = 7261 and a.TypeID = 26 then 108
				When b.ItemID = 7262 and a.TypeID = 26 then 109
				When b.ItemID = 7260 and a.TypeID = 27 then 110
				When b.ItemID = 7261 and a.TypeID = 27 then 111
				When b.ItemID = 7262 and a.TypeID = 27 then 112

				Else 0
			End as [AdditionalCashbackAdjustmentTypeID]
		FROM #Trans as a
		INNER JOIN SLC_report.dbo.Trans as b 
			on a.ItemID = b.ID
		-- (104991 rows affected) / 00:00:01

	EXEC [Monitor].[ProcessLog_Insert] 'Transactions_AdditionalCashbackAdjustment', 'Finished'


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