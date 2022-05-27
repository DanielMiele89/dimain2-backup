CREATE PROCEDURE [gas].[CombinationReview_AcceptChanges] 
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
		UPDATE Staging.CTLoad_MIDINewCombo
		SET SuggestedBrandID = ct.BrandID
		FROM Staging.CTLoad_MIDINewCombo cr
		INNER JOIN @ChangeTable ct ON cr.ID = ct.CombinationReviewID

		--SAFETY CHECK - remove where brandmid already exists - JEA 16/03/2013
		DELETE cr
		FROM Staging.CTLoad_MIDINewCombo cr
		INNER JOIN @ChangeTable ct ON cr.ID = ct.CombinationReviewID
		INNER JOIN Relational.ConsumerCombination b ON cr.SuggestedBrandID = b.BrandID
			AND cr.MID = B.MID
			AND cr.LocationCountry = b.LocationCountry
			AND cr.Narrative = b.Narrative
			AND cr.IsHighVariance = b.IsHighVariance
			AND cr.MCCID = b.MCCID
			AND cr.OriginatorID = b.OriginatorID

		--create BrandMID records where they do not yet exist
		INSERT INTO Staging.CTLoad_MIDIMatched(MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, SuggestedBrandID)
		SELECT DISTINCT cr.MID, cr.Narrative, cr.LocationCountry, cr.MCCID, cr.OriginatorID, cr.IsHighVariance, cr.SuggestedBrandID
		FROM Staging.CTLoad_MIDINewCombo cr
		INNER JOIN @ChangeTable ct ON cr.ID = ct.CombinationReviewID

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


