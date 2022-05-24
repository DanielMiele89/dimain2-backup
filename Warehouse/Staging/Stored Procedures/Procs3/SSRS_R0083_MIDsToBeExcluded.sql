

-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 11/04/2016
-- Description: Excluding MID's into exclusion table
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0083_MIDsToBeExcluded](
			@MID1 varchar(50))
									
AS

	SET NOCOUNT ON;


----------------------------------------------------------------------------------------
----------------Exclude MIDs that is/are 'BAD DATA'-----------------
----------------------------------------------------------------------------------------
--Declare @MID_1 varchar(50)

--Set @MID = @MID_1

declare @MID as varchar
set @MID = @MID1

INSERT INTO Staging.BrandSuggestionRejected (MID)
SELECT MID = @MID 


UPDATE [Staging].[BrandSuggestionRejected]
SET	ConsumerCombinationID = cc.ConsumerCombinationID--,
	--BrandID = cc.BrandID
FROM [Warehouse].[Staging].[BrandSuggestionRejected] AS bsr
INNER JOIN Warehouse.Relational.ConsumerCombination AS cc
	ON cc.MID = bsr.MID
WHERE bsr.ConsumerCombinationID IS NULL
	--AND bsr.BrandID IS NULL