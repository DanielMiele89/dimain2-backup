/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Clears, inserts and recreates index on table that holds the latest
				postcode for each MID from the Credit Card data

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/

CREATE PROCEDURE [Processing].[MerchantPostcode_Build]
AS 
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.MerchantPostcodes;

	IF EXISTS (
		SELECT 1
		FROM sys.indexes 
		WHERE name='ucx_Processing_merchantpostcodes' AND object_id = OBJECT_ID('Processing.MerchantPostcodes')
	)
		DROP INDEX ucx_Processing_merchantpostcodes
			ON [Processing].[MerchantPostcodes]

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.MerchantPostcodes
	(
		MerchantID
		, MerchantZip
		, MerchantDBAName
	)
	SELECT
		MerchantID
		, MerchantZip
		, MerchantDBAName
	FROM (
		SELECT CAST(MerchantID AS VARCHAR(15)) AS MerchantID
			, MerchantZip
			, MerchantDBAName
			, ROW_NUMBER() OVER (PARTITION BY MerchantID ORDER BY TranDate DESC) rw
		FROM Archive_Light..CBP_Credit_TransactionHistory t
		WHERE MerchantID not in ('00000000000000', '000000000000000', '')
	) tbl
	WHERE rw = 1

	SELECT @RowCount = @@rowcount	

	----------------------------------------------------------------------
	-- Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX ucx_Processing_merchantpostcodes ON [Processing].[MerchantPostcodes]
	(
		[MerchantID] ASC
	)

	RETURN @RowCount

END
