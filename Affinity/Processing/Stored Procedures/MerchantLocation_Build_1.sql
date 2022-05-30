/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 17/06/2020
-- Description:	Clears, inserts and indexes table that holds the latest location
				details for each combination from the Location table

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/

CREATE PROCEDURE [Processing].[MerchantLocation_Build]
AS 
BEGIN

	DECLARE @RowCount INT -- Logging row count
	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.MerchantLocation;

	IF EXISTS (
		SELECT 1
		FROM sys.indexes 
		WHERE name='ucx_Processing_merchantlocation' AND object_id = OBJECT_ID('Processing.MerchantLocation')
	)
		DROP INDEX ucx_Processing_merchantlocation 
			ON [Processing].[MerchantLocation]

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.MerchantLocation (ConsumerCombinationID, LocationAddress)
	SELECT ConsumerCombinationID, LocationAddress
	FROM (
		SELECT top 1
			l.ConsumerCombinationID
			, l.LocationAddress
			, l.LocationID
			, ROW_NUMBER() OVER (PARTITION BY consumercombinationid ORDER BY LocationID DESC) RowNum
		FROM Warehouse.Relational.Location l
	) d
	WHERE RowNum = 1

	SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------

	CREATE UNIQUE CLUSTERED INDEX ucx_Processing_merchantlocation ON [Processing].[MerchantLocation]
	(
		[ConsumerCombinationID] ASC
	)

	RETURN @RowCount

END
