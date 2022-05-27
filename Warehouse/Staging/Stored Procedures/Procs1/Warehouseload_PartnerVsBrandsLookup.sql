/*

	Author:			Stuart Barnley

	Date:			17th February 2017

	Purpose:		To provide a Brand vs. PartnerID table that includes multiple partner records


*/
CREATE Procedure [Staging].[Warehouseload_PartnerVsBrandsLookup] 
--With Execute as Owner
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	Declare @Today datetime = Getdate()

	------------------------------------------------------------------------------------------------------
	-------------------------------Write Entry to Joblog_Temp---------------------------------------------
	------------------------------------------------------------------------------------------------------
	INSERT INTO Staging.JobLog_Temp
	SELECT	StoredProcedureName = 'Warehouseload_PartnerVsBrandsLookup',
		TableSchemaName = 'Relational',
		TableName = 'Partners_Vs_Brands',
		StartDate = @Today,
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'R'

	------------------------------------------------------------------------------------------------------
	---------------------------Find a distinct list of Primary Partner Records----------------------------
	------------------------------------------------------------------------------------------------------

	Select	PrimaryPartnerID,
			ROW_NUMBER() OVER (ORDER BY PrimaryPartnerID) AS GroupNo
	Into #PrimaryPartners
	From (
			Select Distinct PrimaryPartnerID
			From Iron.PrimaryRetailerIdentification as pri
			Where pri.PrimaryPartnerID is not null
	) as a

	------------------------------------------------------------------------------------------------------
	---------------------------Find a list of Multiple Partner Record merchants---------------------------
	------------------------------------------------------------------------------------------------------

	Select	pri.PartnerID,
			pri.PrimaryPartnerID,
			GroupNo
	Into	#MultiplePartners
	From Iron.PrimaryRetailerIdentification as pri
	inner join #PrimaryPartners as p
		on pri.PrimaryPartnerID = p.PrimaryPartnerID
	Where pri.PrimaryPartnerID is not null
	Union All
	Select	pp.PrimaryPartnerID as PartnerID,
			pp.PrimaryPartnerID,
			GroupNo
	From #PrimaryPartners as pp
	Order by 2,1

	------------------------------------------------------------------------------------------------------
	----------------------------Find the Brand IDs from MI.PartnerBrands Table----------------------------
	------------------------------------------------------------------------------------------------------

	Select	mp.*,
			BrandID
	into #InitialBrandIDs
	From #MultiplePartners as mp
	Left Outer join MI.PartnerBrand as pb
		on mp.PartnerID = pb.PartnerID

	------------------------------------------------------------------------------------------------------
	---------------------------Duplicate Brand IDs identified for secondary records-----------------------
	------------------------------------------------------------------------------------------------------

	Update a
	Set a.BrandID = b.BrandID
	From #InitialBrandIDs as a
	inner join #InitialBrandIDs as b
		on	a.PrimaryPartnerID = b.PrimaryPartnerID and
			a.PartnerID <> b.PartnerID and
			a.BrandID is null and
			b.BrandID is not null

	------------------------------------------------------------------------------------------------------
	-----------------------------------Delete Rows that could not be matched------------------------------
	------------------------------------------------------------------------------------------------------

	Delete from #InitialBrandIDs
	Where BrandID is null

	------------------------------------------------------------------------------------------------------
	------------------Create Table with contents of MI table and this new data combined-------------------
	------------------------------------------------------------------------------------------------------
	Truncate Table Staging.Partners_Vs_Brands

	Insert into Staging.Partners_Vs_Brands
	Select * 
	From MI.PartnerBrand as pb
	union
	Select	PartnerID,
			BrandID
	From	#InitialBrandIDs
	Order by BrandID

	--------------------------------------------------------------------------------------------
	------------------------Write Entry to Joblog_Temp and update Joblog------------------------
	--------------------------------------------------------------------------------------------

	Set @Today = Getdate()

	UPDATE	Staging.JobLog_Temp
	SET		EndDate = @Today
	WHERE	StoredProcedureName = 'Warehouseload_PartnerVsBrandsLookup' 
		AND TableSchemaName = 'Relational'
		AND TableName = 'Partners_Vs_Brands'
		AND EndDate IS NULL


	INSERT INTO Staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM Staging.JobLog_Temp

	TRUNCATE TABLE Staging.JobLog_Temp
	

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