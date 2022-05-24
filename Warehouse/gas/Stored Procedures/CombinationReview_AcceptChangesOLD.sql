CREATE PROCEDURE [gas].[CombinationReview_AcceptChangesOLD] 
	-- Add the parameters for the stored procedure here
	(
		@Changes VARCHAR(MAX)
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	--table for accepted rows
    DECLARE @ChangeTable TABLE(CombinationReviewID INT PRIMARY KEY
		, BrandID SMALLINT)

	--table for new Brand MID output
	DECLARE @BrandMIDNew TABLE(BrandMIDID INT PRIMARY KEY
		, BrandID SMALLINT
		, MID VARCHAR(50)
		, Country VARCHAR(3)
		, Narrative VARCHAR(50)
		, IsHighVariance BIT)

	--begin error-trapped section
	BEGIN TRY 
		--if an error occurs, make no changes 
		BEGIN TRAN

		--collect set of accepted values
		INSERT INTO @ChangeTable
		SELECT LeftItem, RightItem
		FROM dbo.SplitWithPairs(@Changes, ';', ',')
		ORDER BY LeftItem;

		--update Brand ID to the value that has been selected
		UPDATE Staging.CombinationReview
		SET SuggestedBrandID = ct.BrandID
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID

		--SAFETY CHECK - remove where brandmid already exists - JEA 16/03/2013
		DELETE cr
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
		INNER JOIN Relational.BrandMID b ON cr.SuggestedBrandID = b.BrandID
			AND cr.MID = B.MID
			AND cr.LocationCountry = b.Country
			AND cr.Narrative = b.Narrative
			AND cr.IsHighVariance = b.IsHighVariance

		--safety check to ensure that there are no duplicate combinations
		DELETE cr
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
		INNER JOIN Staging.Combination c ON cr.BrandMIDID = c.BrandMIDID 
			AND cr.Narrative = c.Narrative
			AND cr.LocationCountry = c.LocationCountry

		--create BrandMID records where they do not yet exist
		INSERT INTO Relational.BrandMID(BrandID, MID, Country, Narrative, IsHighVariance)
		OUTPUT inserted.BrandMIDID, inserted.BrandID, inserted.MID, inserted.Country, inserted.Narrative, inserted.IsHighVariance
		INTO @BrandMIDNew
		SELECT DISTINCT cr.SuggestedBrandID, cr.MID, cr.LocationCountry, cr.Narrative, cr.IsHighVariance
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
		WHERE cr.BrandMIDID IS NULL

		--set BrandMIDID where the BrandMID has just been created
		UPDATE cr
		SET BrandMIDID = b.BrandMIDID
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
		INNER JOIN Relational.BrandMID b ON cr.SuggestedBrandID = b.BrandID
			AND cr.MID = B.MID
			AND cr.LocationCountry = b.Country
			AND cr.Narrative = b.Narrative
			AND cr.IsHighVariance = b.IsHighVariance
		WHERE cr.BrandMIDID IS NULL






		--create new combinations
		INSERT INTO Staging.Combination(LocationCountry, MID, Narrative, IsHighVariance
			, BrandMIDID, Inserted, LastMatched, CombinationReviewID)
		SELECT DISTINCT cr.LocationCountry, cr.MID, cr.Narrative, cr.IsHighVariance  --DISTINCT SAFETY CHECK PREVENT DUPES
			, cr.BrandMIDID, GETDATE(), GETDATE(), cr.CombinationReviewID
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID
		WHERE NOT cr.BrandMIDID IS NULL  --SAFETY CHECK PREVENT UNRESOLVED INSERTS

		--insert records created for live partners into LivePartnerReview
		INSERT INTO Staging.LivePartnerReview(MID, Narrative, [Address], MCC, MCCDesc, BrandMIDID, CombinationReviewID)
		SELECT DISTINCT C.MID, C.Narrative, C.LocationAddress, C.MCC, M.MCCDesc, C.BrandMIDID, C.CombinationReviewID
		FROM Staging.CombinationReview C
		INNER JOIN Relational.MCCList M ON C.MCC = M.MCC
		INNER JOIN @ChangeTable ct ON C.CombinationReviewID = ct.CombinationReviewID
		INNER JOIN Relational.Brand B ON C.SuggestedBrandID = B.BrandID
		WHERE B.IsLivePartner = 1
		EXCEPT
		SELECT MID, Narrative, [Address], MCC, MCCDesc, BrandMIDID, CombinationReviewID
		FROM Staging.LivePartnerReview

		--Remove resolved cases
		DELETE FROM Staging.CombinationReview
		FROM Staging.CombinationReview cr
		INNER JOIN @ChangeTable ct ON cr.CombinationReviewID = ct.CombinationReviewID






		--if no error has occurred, write to the database
		COMMIT TRAN



	END TRY
	BEGIN CATCH
		--undo work done
		ROLLBACK TRAN

		--collect error information
		SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

		--display error to user
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH


END