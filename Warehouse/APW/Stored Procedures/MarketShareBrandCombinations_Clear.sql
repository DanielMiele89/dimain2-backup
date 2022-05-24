-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Clears brand and competitor combinations
-- =============================================
CREATE PROCEDURE [APW].[MarketShareBrandCombinations_Clear]

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.MarketShareCombination

END