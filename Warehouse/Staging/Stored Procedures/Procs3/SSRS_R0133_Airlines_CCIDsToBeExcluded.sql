


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 14/10/2016
-- Description: Excluding CCID's into exclusion table
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0133_Airlines_CCIDsToBeExcluded](
			@CC int,@MID varchar(50),@BrandID smallint)
									
AS

	SET NOCOUNT ON;

/************************************************************
********* Brands the required ConsumerCombinationID *********
************************************************************/

INSERT INTO	[Staging].[BrandSuggestionRejected] --(ConsumerCombinationID, MID, BrandID)
SELECT		@Mid,@cc,@BrandID