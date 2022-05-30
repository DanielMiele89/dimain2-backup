/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Clears, inserts and recreate indexes on table that holds
				the Merchant File to be produced and outputs the number of rows
				inserted

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Merchant_Staging_Build](
	@MaxLoopID INT OUTPUT -- The number of rows that were insertered
)
AS
BEGIN

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.FileExtraction_Merchant_Staging

	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'ucix_Processing_extract_merchant'
				AND object_id = OBJECT_ID('Processing.FileExtraction_Merchant_Staging')
		)
		DROP INDEX ucix_Processing_extract_merchant ON Processing.FileExtraction_Merchant_Staging

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.FileExtraction_Merchant_Staging
	(
		RewardProxyMIDTupleID
	  , MCCCode
	  , RewardProxyMID
	  , MerchantDescriptor
	  , MerchantPostcode
	  , MerchantName
	  , MerchantLocation
	  , CountryCode
	)

	 SELECT
		 x.ProxyMIDTupleID AS RewardProxyMIDTupleID
	   , MCC			   AS MCCCode
	   , x.ProxyMID		   AS RewardProxyMID
	   , MaskedNarrative   AS MerchantDescriptor
	   , MerchantZip	   AS MerchantPostcode
	   , BrandName		   AS MerchantName
	   , LocationAddress   AS MerchantLocation
	   , LocationCountry   AS CountryCode
	 FROM (
		-- some combinations share the same set of characteristics so use the first combination that was created
			-- the first was chosen mainly due to it making more sense from examples that were observed
		 SELECT
			 cc.ProxyMIDTupleID
		   , cc.MCC
		   , cc.ProxyMID
		   , cc.MaskedNarrative
		   , cc.MerchantZip
		   , cc.BrandName
		   , cc.LocationAddress
		   , cc.LocationCountry
		   , ROW_NUMBER() OVER (PARTITION BY ProxyMIDTupleID ORDER BY cc.ConsumerCombinationID) rw
		 FROM Processing.ConsumerCombination cc
	 ) x
	 WHERE rw = 1

	SET @MaxLoopID = @@rowcount

	INSERT INTO Processing.FileExtraction_Merchant_Staging
	(
		RewardProxyMIDTupleID
	  , MCCCode
	  , RewardProxyMID
	  , MerchantDescriptor
	  , MerchantPostcode
	  , MerchantName
	  , MerchantLocation
	  , CountryCode
	)
	 SELECT
		 x.ProxyMIDTupleID AS RewardProxyMIDTupleID
	   , MCC			   AS MCCCode
	   , x.ProxyMID		   AS RewardProxyMID
	   , Narrative   AS MerchantDescriptor
	   , MerchantZip	   AS MerchantPostcode
	   , BrandName		   AS MerchantName
	   , LocationAddress   AS MerchantLocation
	   , LocationCountry   AS CountryCode
	 FROM (
		SELECT
			cc.ProxyMIDTupleID
			, cc.MCC
			, cc.ProxyMID
			, cc.Narrative
			, cx.MerchantZip
			, cx.BrandName
			, cx.LocationAddress
			, cc.LocationCountry
			, ROW_NUMBER() OVER (PARTITION BY cc.ProxyMIDTupleID ORDER BY cc.ConsumerCombinationID) rw
		FROM  dbo.OldMIDTupleID cc
		JOIN Processing.ConsumerCombination cx
			ON cc.ConsumerCombinationID = cx.ConsumerCombinationID
		WHERE NOT EXISTS (
			SELECT 1
			FROM Processing.FileExtraction_Merchant_Staging x
			WHERE cc.ProxyMIDTupleID = x.RewardProxyMIDTupleID
		)
	) x
	WHERE rw = 1

	SET @MaxLoopID += @@ROWCOUNT
	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX ucix_Processing_extract_merchant ON Processing.FileExtraction_Merchant_Staging (LoopID)

	RETURN @MaxLoopID

END
