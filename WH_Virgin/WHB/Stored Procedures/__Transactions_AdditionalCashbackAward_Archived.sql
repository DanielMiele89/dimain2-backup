-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__Transactions_AdditionalCashbackAward_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'Transactions_AdditionalCashbackAward', 'Started'

	-------------------------------------------------------------------------------
	--EXEC WHB.AdditionalCashbackAward_V1_11_Append ###############################
	-------------------------------------------------------------------------------

	Declare 
		@AddedDate date, --********Date of last transaction********--
		@AddedDateTime datetime, --********Datetime of last transaction********--
		@ACA_ID int
		

	--Find Last record Imported (Find the last processed date so that we only import rows after this day)
	SELECT 
		@AddedDate = Max(AddedDate), 
		@ACA_ID = Max(AdditionalCashbackAwardID)
	FROM Derived.AdditionalCashbackAward as aca				

	Set @AddedDate = Dateadd(day,1,@AddedDate)
	Set @AddedDateTime = @AddedDate


	--Get Additional Cashback Awards with a PanID---------------------
	INSERT INTO Derived.AdditionalCashbackAward	
	SELECT t.Matchid as MatchID,
			t.VectorMajorID as FileID,
			t.VectorMinorID as RowNum,
			t.FanID,
			t.[Date] as TranDate,
			t.ProcessDate as AddedDate,
			t.Price as Amount,
			t.ClubCash*tt.Multiplier as CashbackEarned,
			t.ActivationDays,
			tt.AdditionalCashbackAwardTypeID,
			Case
				When CardTypeID = 1 then 1 -- Credit Card
				When CardTypeID = 2 then 0 -- Debit Card
				When t.DirectDebitOriginatorID IS not null then 2 -- Direct Debit
				When tt.AdditionalCashbackAwardTypeID = 11 then 1 -- ApplyPay and Credit Card
				Else 0
			End as PaymentMethodID,
			t.DirectDebitOriginatorID

	FROM (
		SELECT aca.*,tt.Multiplier
		From Warehouse.Relational.AdditionalCashbackAwardType as aca
		INNER JOIN SLC_Report.dbo.TransactionType as tt 
			on	aca.TransactionTypeID = tt.ID	
	) as tt
	
	INNER HASH JOIN SLC_Report.dbo.Trans as t 
		on tt.ItemID = t.ItemID 
		and tt.TransactionTypeID = t.TypeID

	INNER JOIN Derived.Customer as c
		on t.FanID = c.fanid

	LEFT JOIN SLC_Report.dbo.Pan as p
		on t.PanID = p.ID

	LEFT JOIN SLC_Report..PaymentCard as pc
		on p.PaymentCardID = pc.ID

	WHERE t.VectorMajorID is not null 
		and t.VectorMinorID is not null
		and t.ProcessDate >= @AddedDateTime
	

	-- Remove those records with a MatchID and no TRANS record ---------------------
	UPDATE aca
		Set MatchID = m.ID
	FROM Derived.AdditionalCashbackAward as aca
	INNER JOIN SLC_Report..match as m with (nolock)
		on	aca.FileID = m.VectorMajorID and
			aca.RowNum = m.VectorMinorID
	INNER JOIN Derived.PartnerTrans as pt
		on	m.ID = pt.MatchID
	WHERE aca.AdditionalCashbackAwardID >= @ACA_ID


















		-------------------------------------------------------------------------------
		--EXEC WHB.AdditionalCashbackAward_ApplePay_V1_2 ##############################
		-------------------------------------------------------------------------------

		DECLARE @MaxApplePayTran int, @HighestRowNo int

		SELECT 
			@MaxApplePayTran = ISNULL(Max(TranID),0),
			@HighestRowNo = ISNULL(Max(RowNum),0)
		FROM Staging.AdditionalCashbackAward_ApplePay


		--Create Types Table---------------------------------------
		if object_id('tempdb..#Types') is not null drop table #Types
		SELECT aca.*,tt.Multiplier
		INTO #Types
		FROM Warehouse.Relational.[AdditionalCashbackAwardType] as aca
		INNER JOIN SLC_Report.dbo.TransactionType as tt with (Nolock)
			ON	aca.TransactionTypeID = tt.ID
		WHERE Title Like '%Apple Pay%'


		INSERT INTO Staging.AdditionalCashbackAward_ApplePay
		SELECT 
			t.ID as TranID,
			0 as FileID,
			ROW_NUMBER() OVER (ORDER BY t.ID) + @HighestRowNo AS RowNum
		FROM SLC_Report.DBO.Trans t	
		INNER JOIN #Types tt 
			ON tt.ItemID = t.ItemID 
			AND tt.TransactionTypeID = t.TypeID
		INNER JOIN Derived.Customer c 
			ON t.FanID = c.FanID
		WHERE NOT EXISTS (SELECT 1 FROM Staging.AdditionalCashbackAward_ApplePay a WHERE t.ID = a.TranID)

 
		--Find final customers
		INSERT INTO Derived.AdditionalCashbackAward
		SELECT	   
			NULL as MatchID,
			a.FileID as FileID,
			a.RowNum as RowNum,
			t.FanID,
			Cast(t.[Date] as date) as TranDate,
			Cast(t.ProcessDate as date) as AddedDate,
			t.Price as Amount,
			t.ClubCash*tt.Multiplier as CashbackEarned,
			t.ActivationDays,
			tt.AdditionalCashbackAwardTypeID,
			1 as PaymentMethodID,
			NULL as DirectDebitOriginatorID
		FROM Staging.AdditionalCashbackAward_ApplePay as a
		INNER LOOP JOIN SLC_Report..Trans t 
			on a.TranID = t.ID
		INNER JOIN #Types as tt
			on tt.ItemID = t.ItemID 
			and tt.TransactionTypeID = t.TypeID
		WHERE TranID > @MaxApplePayTran ---******INCREMENTAL LOAD ONLY













		
		-------------------------------------------------------------------------------
		--EXEC WHB.AdditionalCashbackAward_ItemAlterations_V1_0 #######################
		-------------------------------------------------------------------------------

		UPDATE b
		SET AdditionalCashbackAwardTypeID = a.AdditionalCashbackAwardTypeID_New
		FROM Warehouse.[Relational].[AdditionalCashbackAwardTypeAdjustments] as a
		INNER JOIN Derived.AdditionalCashbackAward as b
			on a.AdditionalCashbackAwardTypeID_Original = b.AdditionalCashbackAwardTypeID
		WHERE b.Trandate BETWEEN a.StartDate and a.EndDate


	EXEC [Monitor].[ProcessLog_Insert] 'Transactions_AdditionalCashbackAward', 'Finished'


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