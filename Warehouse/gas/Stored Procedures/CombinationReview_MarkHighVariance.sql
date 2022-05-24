
-- =============================================
-- Author:		JEA
-- Create date: 05/10/2012
-- Description:	Marks review cases as high variance and removes duplicates
-- =============================================
CREATE PROCEDURE [gas].[CombinationReview_MarkHighVariance] 
	(
		@HighVarianceIDs VARCHAR(MAX)
		, @Narrative Varchar(50)
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    DECLARE @HighVariance TABLE (ID INT PRIMARY KEY) -- holds the IDs to update
    DECLARE @HighVarianceMID TABLE (MID VARCHAR(50)
		, Narrative VARCHAR(50)
		, LocationCountry VARCHAR(3)
		, MCCID SMALLINT
		, OriginatorID VARCHAR(11)
		, RetainThisID INT)

	BEGIN TRY
	
		--if an error occurs, make no changes
		BEGIN TRAN
		
		--populate the high variance table with IDs from the parameter string
		INSERT INTO @HighVariance(ID)
		SELECT ID
		FROM dbo.SplitInts(@HighVarianceIDs)
	    
	    --mark selected cases as high variance and set them all to the same narrative
		UPDATE Staging.CombinationReview
		SET IsHighVariance = 1,  Narrative = @Narrative
		FROM Staging.CTLoad_MIDINewCombo cr
		INNER JOIN @HighVariance h ON cr.ID = h.ID
		
		--gather all high variance patterns with more than one identical entry
		INSERT INTO @HighVarianceMID(MID, Narrative, LocationCountry, MCCID, OriginatorID)
		SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID
		FROM
		(SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID, COUNT(1) AS Frequency
			FROM Staging.CTLoad_MIDINewCombo
			WHERE IsHighVariance = 1
			GROUP BY MID, Narrative, LocationCountry, MCCID, OriginatorID
			HAVING COUNT(1) > 1) t
		
		--select one example of each to remain	
		UPDATE @HighVarianceMID SET RetainThisID = cr.ID
		FROM @HighVarianceMID H
		INNER JOIN Staging.CTLoad_MIDINewCombo cr ON H.MID = cr.MID 
			AND H.Narrative = CR.Narrative
			AND H.LocationCountry = cr.LocationCountry
			AND H.MCCID = cr.MCCID
			AND h.OriginatorID = cr.OriginatorID
		WHERE cr.IsHighVariance = 1
		
		--remove the rest	
		DELETE FROM Staging.CTLoad_MIDINewCombo
		FROM Staging.CTLoad_MIDINewCombo cr
		INNER JOIN @HighVarianceMID H ON H.MID = cr.MID 
			AND H.Narrative = CR.Narrative
			AND H.LocationCountry = cr.LocationCountry
			AND H.MCCID = cr.MCCID
			AND h.OriginatorID = cr.OriginatorID
			AND H.RetainThisID != cr.ID
		WHERE cr.IsHighVariance = 1
		
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

