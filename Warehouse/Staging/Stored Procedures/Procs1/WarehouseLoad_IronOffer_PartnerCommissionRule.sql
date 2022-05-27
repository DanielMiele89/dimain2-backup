/*
Author:		Suraj Chahal
Date:		15 Jul 2014
Purpose:	Reload PartnerCommissionRule data from SLC report into Warehouse database.

*/
CREATE PROCEDURE [Staging].[WarehouseLoad_IronOffer_PartnerCommissionRule]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule',
		TableSchemaName = 'Relational',
		TableName = 'IronOffer_PartnerCommissionRule',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'R'


	/*--------------------------------------------*/
	----------Truncate table before reload----------
	/*--------------------------------------------*/
	TRUNCATE TABLE Relational.IronOffer_PartnerCommissionRule



	/*---------------------------------------------------*/
	----------Reload PartnerCommissionRule Data----------
	/*---------------------------------------------------*/
	INSERT INTO Relational.IronOffer_PartnerCommissionRule
	SELECT	ID as PCR_ID,
		PartnerID,
		TypeID,
		CommissionRate,
		Status,
		Priority,
		DeletionDate,
		MaximumUsesPerFan as MaximumUsesPerFan,
		RequiredNumberOfPriorTransactions as NumberofPriorTransactions,
		RequiredMinimumBasketSize as MinimumBasketSize,
		RequiredMaximumBasketSize as MaximumBasketSize,
		RequiredChannel as Channel,
		RequiredClubID as ClubID,
		RequiredIronOfferID as IronOfferID,
		RequiredRetailOutletID as OutletID,
		RequiredCardholderPresence as CardHolderPresence
	FROM SLC_Report..PartnerCommissionRule
	WHERE RequiredIronOfferID IS NOT NULL
	ORDER BY IronOfferID, TypeID



-- Insert PCR rules for MFDD

	if object_id('tempdb..#MFDDPARTNERS') is not null drop table #MFDDPARTNERS

	
	Select * 
		Into #MFDDPARTNERS
	from (
		Select io.IronOfferID,io.PartnerID, case when IronOfferName like '%MFDD%' THEN 2 ELSE 1 END AS OfferType
		From relational.IronOffer as io
		Where --IsSignedOff = 1
					(io.EndDate IS NULL OR io.EndDate >= GETDATE())
					AND io.IsTriggerOffer = 0
				--	and StartDate <= @Date
	) x 
	where OfferType = 2

	Insert into Relational.IronOffer_PartnerCommissionRule_MFDD (IronOfferID)
	Select io.IronOfferID
	from #MFDDPartners p
	Inner Join Relational.IronOffer io 
		on io.PartnerID = p.PartnerID
	Left Join Relational.IronOffer_PartnerCommissionRule_MFDD mfdd 
		on mfdd.ironofferid = io.IronOfferID
	where mfdd.ironofferid is null
	and io.IronOfferName like '%MFDD%'

	

	


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	UPDATE  staging.JobLog_Temp
	SET	EndDate = GETDATE()
	WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOffer_PartnerCommissionRule' and
		EndDate is null
		
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	UPDATE  staging.JobLog_Temp
	SET	TableRowCount = (Select COUNT(*) from Warehouse.Relational.IronOffer_PartnerCommissionRule)
	WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOffer_PartnerCommissionRule' and
		TableRowCount IS NULL


	INSERT INTO staging.JobLog
	SELECT	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
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

