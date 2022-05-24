
/*******************************************************************************

	Author: Suraj Chahal
	Create date: 14/05/2015
	Description: Updates the CurrentlyActive field on the Partner Table. 

*******************************************************************************/

CREATE PROCEDURE [WHB].[Partners_CurrentlyActive_V2]
		
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/******************************************************************************
	***********************Write entry to JobLog Table*****************************
	******************************************************************************/
	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID),
		TableSchemaName = 'Relational',
		TableName = 'Partner',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'U'


-----------------------------------------------------------------------------------------------
-- Fetch all live offers

	DECLARE @GETDATE DATETIME = CONVERT(DATE, GETDATE())

	---Find active offers
	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
	SELECT	iof.IronOfferID
		,	iof.PartnerID
		,	CASE
				WHEN IronOfferName LIKE '%MFDD%' THEN 2
				ELSE 1
			END AS OfferType
	INTO #IronOffer
	FROM [Relational].[IronOffer] iof
	Where IsSignedOff = 1
	AND (iof.EndDate IS NULL OR @GETDATE <= iof.EndDate)
	AND iof.IsTriggerOffer = 0
	and StartDate <= @GETDATE

-----------------------------------------------------------------------------------------------
-- TRANSACTIONTYPEID FLAG

	UPDATE pa
	SET TransactionTypeID = OfferType
	FROM [Relational].[Partner] pa
	INNER JOIN #IronOffer iof
		ON pa.PartnerID = iof.PartnerID

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer (IronOfferID)

-------------------------------------------------------------------------------------------
-- CURRENTLY ACTIVE FLAG 

	UPDATE [Relational].[Partner]
	SET CurrentlyActive = 0
	
	---Check offers have members

	IF OBJECT_ID('tempdb..#CurrentOffers') IS NOT NULL DROP TABLE #CurrentOffers
	SELECT	iof.IronOfferID
		,	iof.PartnerID
	INTO #CurrentOffers
	FROM #IronOffer iof
	WHERE EXISTS (	SELECT 1
					FROM [Relational].[IronOfferMember] iom WITH (NOLOCK)
					WHERE iof.IronOfferID = iom.IronOfferID
					AND (iom.EndDate IS NULL OR @GETDATE <= iom.EndDate))
	UNION ALL
	SELECT	iof.IronOfferID
		,	iof.PartnerID
	FROM #IronOffer iof
	WHERE EXISTS (	SELECT 1
					FROM [iron].[OfferMemberAddition] oma
					WHERE iof.IronOfferID = oma.IronOfferID)

	CREATE CLUSTERED INDEX cix_CurrentOffers_PartnerID on #CurrentOffers (PartnerID)

	---Update partner records

	UPDATE pa
	SET CurrentlyActive = 1
	FROM [Relational].[Partner] pa
	WHERE EXISTS (	SELECT 1
					FROM #CurrentOffers co
					WHERE pa.PartnerID = co.PartnerID)

	
-----------------------------------------------------------------------------------------------


	/******************************************************************************
	****************Update entry in JobLog Table with End Date*********************
	******************************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) 
		AND TableSchemaName = 'Relational'
		AND TableName = 'Partner' 
		AND EndDate IS NULL

	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = (SELECT COUNT(1) FROM Relational.Partner)
	WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID)
		AND TableSchemaName = 'Relational'
		AND TableName = 'Partner' 
		AND TableRowCount IS NULL


	INSERT INTO Staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM Staging.JobLog_Temp

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

End