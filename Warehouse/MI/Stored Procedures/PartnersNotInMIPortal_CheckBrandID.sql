-- =============================================
-- Author:		JEA
-- Create date: 20/10/2014
-- Description:	Retrieves all partner brand IDs for Cashback Plus
-- for checking against the MI Portal by an SSIS Task
-- =============================================
CREATE PROCEDURE [MI].[PartnersNotInMIPortal_CheckBrandID] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CAST(BrandID AS SMALLINT) AS BrandID
	FROM Relational.[Partner]
	WHERE BrandID IS NOT NULL
	ORDER BY BrandID

END