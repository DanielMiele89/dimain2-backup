
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Clears, inserts and recreates indexes on table to hold ConsumerCombinations
				that will go through the masking process.

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_ConsumerCombinations_Build]
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.Masking_ConsumerCombinations;

	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'ucix_Processing_consumercombinations'
				AND object_id = OBJECT_ID('Processing.Masking_ConsumerCombinations')
		)
		DROP INDEX ucix_Processing_consumercombinations ON Processing.Masking_ConsumerCombinations

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.Masking_ConsumerCombinations
	(
		ConsumerCombinationID
	  , BrandMIDID
	  , BrandID
	  , MID
	  , Narrative
	  , LocationCountry
	  , MCCID
	  , OriginatorID
	  , IsHighVariance
	  , IsUKSpend
	  , PaymentGatewayStatusID
	  , IsCreditOrigin
	  , isGB
	  , isBlanketMask
	  , rw
	)
	 SELECT
		 x.ConsumerCombinationID
	   , x.BrandMIDID
	   , x.BrandID
	   , x.MID
	   , x.Narrative
	   , x.LocationCountry
	   , x.MCCID
	   , x.OriginatorID
	   , x.IsHighVariance
	   , x.IsUKSpend
	   , x.PaymentGatewayStatusID
	   , x.IsCreditOrigin
	   , gb.isGB
	   , ~gb.isGB AS isBlanketMask
	   , ROW_NUMBER() OVER (PARTITION BY x.MID, x.BrandID ORDER BY x.ConsumerCombinationID DESC)			   rw -- for nFI joins since they have a MID and BrandID
	 FROM Warehouse.Relational.ConsumerCombination x
	 LEFT JOIN Warehouse.Relational.MCCList mcc
		 ON mcc.MCCID = x.MCCID
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT) -- 1 if country is classed as 'GB'
		FROM dbo.Masking_GBCountries g
		WHERE x.LocationCountry = g.CountryCode
	) gb(isGB)

	SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX ucix_Processing_consumercombinations ON Processing.Masking_ConsumerCombinations (ConsumerCombinationID, MID, isGB)

	RETURN @RowCount

END
