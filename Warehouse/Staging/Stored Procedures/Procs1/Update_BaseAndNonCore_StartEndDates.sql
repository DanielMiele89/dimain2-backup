

-- **********************************************************************************
-- Author: Suraj Chahal
-- Create date: 05/05/2015
-- Description: Update Start and End dates for PartnerOffers_Base and NonCore table
-- **********************************************************************************
CREATE PROCEDURE [Staging].[Update_BaseAndNonCore_StartEndDates]
			
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
	SELECT	StoredProcedureName = 'Update_BaseAndNonCore_StartEndDates',
		TableSchemaName = 'Staging',
		TableName = 'MultipleTables',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'U'


	/***************************************************************************************************/

	/**********************************************************
	**************Update PartnerOffers_Base Table**************
	**********************************************************/
	UPDATE Relational.PartnerOffers_Base
	SET StartDate = io.StartDate
	FROM Relational.PartnerOffers_Base pob
	INNER JOIN Relational.IronOffer io
		ON pob.OfferID = io.IronOfferID


	UPDATE Relational.PartnerOffers_Base
	SET EndDate = io.EndDate
	FROM Relational.PartnerOffers_Base pob
	INNER JOIN Relational.IronOffer io
		ON pob.OfferID = io.IronOfferID


	/**********************************************************
	**************Update Partner_BaseOffer Table**************
	**********************************************************/
	UPDATE Relational.Partner_BaseOffer
	SET StartDate = io.StartDate
	FROM Relational.Partner_BaseOffer pob
	INNER JOIN Relational.IronOffer io
		ON pob.OfferID = io.IronOfferID


	UPDATE Relational.Partner_BaseOffer
	SET EndDate = io.EndDate
	FROM Relational.Partner_BaseOffer pob
	INNER JOIN Relational.IronOffer io
		ON pob.OfferID = io.IronOfferID


	
	/**********************************************************
	**************Update Partner_NonCoreBaseOffer**************
	**********************************************************/
	UPDATE Relational.Partner_NonCoreBaseOffer
	SET StartDate = io.StartDate
	FROM Relational.Partner_NonCoreBaseOffer ncb
	INNER JOIN Relational.IronOffer io
		ON ncb.IronOfferID = io.IronOfferID


	UPDATE Relational.Partner_NonCoreBaseOffer
	SET EndDate = io.EndDate
	FROM Relational.Partner_NonCoreBaseOffer ncb
	INNER JOIN Relational.IronOffer io
		ON ncb.IronOfferID = io.IronOfferID


	/***************************************************************************************************/

	/******************************************************************************
	****************Update entry in JobLog Table with End Date*********************
	******************************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = 'Update_BaseAndNonCore_StartEndDates' 
		AND TableSchemaName = 'Staging'
		AND TableName = 'MultipleTables' 
		AND EndDate IS NULL

	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = 0
	WHERE	StoredProcedureName = 'Update_BaseAndNonCore_StartEndDates'
		AND TableSchemaName = 'Staging'
		AND TableName = 'MultipleTables' 
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


END