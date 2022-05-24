-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__PartnersOffers_PartnerVsBrandsLookup_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_PartnerVsBrandsLookup', 'Started'


		IF OBJECT_ID ('tempdb..#InitialBrandIDs') IS NOT NULL DROP TABLE #InitialBrandIDs;
		;WITH FilteredSet AS (
			SELECT PartnerID, PrimaryPartnerID, GroupNo = DENSE_RANK() OVER(ORDER BY PrimaryPartnerID) 
			FROM Warehouse.Iron.PrimaryRetailerIdentification 
			WHERE PrimaryPartnerID is not null
		),
		MultiplePartners AS (
			SELECT PartnerID, PrimaryPartnerID, GroupNo
			FROM FilteredSet 
			UNION ALL
			SELECT PartnerID = PrimaryPartnerID, PrimaryPartnerID, GroupNo
			FROM FilteredSet
			GROUP BY PrimaryPartnerID, GroupNo
		)
		SELECT	mp.*,
			BrandID 
		INTO #InitialBrandIDs
		FROM MultiplePartners mp
		LEFT JOIN Warehouse.MI.PartnerBrand pb
			ON mp.PartnerID = pb.PartnerID


		--Duplicate Brand IDs identified for secondary records
		UPDATE a
		SET a.BrandID = b.BrandID
		FROM #InitialBrandIDs as a
		inner join #InitialBrandIDs as b
			on	a.PrimaryPartnerID = b.PrimaryPartnerID and
				a.PartnerID <> b.PartnerID and
				a.BrandID is null and
				b.BrandID is not null


		--Delete Rows that could not be matched
		DELETE FROM #InitialBrandIDs
		WHERE BrandID is null


		--Create Table with contents of MI table and this new data combined
		TRUNCATE TABLE Staging.Partners_Vs_Brands
		INSERT INTO Staging.Partners_Vs_Brands
		SELECT * 
		FROM Warehouse.MI.PartnerBrand as pb
		UNION
		SELECT	PartnerID, BrandID
		FROM	#InitialBrandIDs
		
	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_PartnerVsBrandsLookup', 'Finished'


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