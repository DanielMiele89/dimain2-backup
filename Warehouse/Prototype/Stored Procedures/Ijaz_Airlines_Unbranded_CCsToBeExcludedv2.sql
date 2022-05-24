


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 13/06/2016
-- Description: Excluding CCID's into exclusion table
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[Ijaz_Airlines_Unbranded_CCsToBeExcludedv2](
			@CC int,@MID varchar(50),@BrandID smallint)
									
AS

	SET NOCOUNT ON;

/************************************************************
********* Brands the required ConsumerCombinationID *********
************************************************************/

INSERT INTO	[Staging].[BrandSuggestionRejected] --(ConsumerCombinationID, MID, BrandID)
SELECT		@Mid,@cc,@BrandID