
/*******************************************************************************

	Author: Suraj Chahal
	Create date: 14/05/2015
	Description: Updates the CurrentlyActive field on the Partner Table. 

*******************************************************************************/

CREATE PROCEDURE [WHB].[Partners_CurrentlyActive_V1_1]
		
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



-------------------------------------------------------------------------------------------
-- CURRENTLY ACTIVE FLAG 

	UPDATE Relational.Partner
	Set CurrentlyActive = 0


	Declare @Date Date = Cast(Getdate() as date)

	---Find active offers
	if object_id('tempdb..#Offers') is not null drop table #Offers
	Select io.IronOfferID,io.PartnerID, case when IronOfferName like '%MFDD%' THEN 2 ELSE 1 END AS OfferType
	Into #Offers
	From relational.IronOffer as io
	Where IsSignedOff = 1
				AND (io.EndDate IS NULL OR io.EndDate >= GETDATE())
				AND io.IsTriggerOffer = 0
				and StartDate <= @Date

	Create Clustered index cix_Offers_IronOfferID on #Offers (IronOfferID)

	---Check offers have members

	if object_id('tempdb..#CurrentOffers') is not null drop table #CurrentOffers

	Select Distinct PartnerID
	Into #CurrentOffers
	From #Offers as o
	inner join slc_report.dbo.ironoffermember as i
		on o.IronOfferID = i.IronOfferID

	Create Clustered index cix_CurrentOffers_PartnerID on #CurrentOffers (PartnerID)

	---Update partner records

	Update Relational.Partner
	Set CUrrentlyActive = 1
	Where PartnerID in (Select PartnerID from #CUrrentOffers)

-----------------------------------------------------------------------------------------------
-- TRANSACTIONTYPEID FLAG

	-- Upcoming offers
	if object_id('tempdb..#Offers2') is not null drop table #Offers2
	Select io.IronOfferID,io.PartnerID, case when IronOfferName like '%MFDD%' THEN 2 ELSE 1 END AS OfferType
	Into #Offers2
	From relational.IronOffer as io
	Where --IsSignedOff = 1
				(io.EndDate IS NULL OR io.EndDate >= GETDATE())
				AND io.IsTriggerOffer = 0
			--	and StartDate <= @Date


	Update p
	Set TransactionTypeID = OfferType
	from Relational.Partner p
	Left join #Offers2 o 
		on o.PartnerID = p.PartnerID
	where p.TransactionTypeID is null

	
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
