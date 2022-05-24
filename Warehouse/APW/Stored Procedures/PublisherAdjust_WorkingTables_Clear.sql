-- =============================================
-- Author:		JEA
-- Create date: 07/10/2016
-- Description:	Clears working tables involved
-- in the publisher adjustment process
-- =============================================
CREATE PROCEDURE [APW].[PublisherAdjust_WorkingTables_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.PublisherAdjust_Brand
	TRUNCATE TABLE APW.PublisherAdjust_RetailerCombination
	TRUNCATE TABLE APW.PublisherAdjust_PublisherBrand

END