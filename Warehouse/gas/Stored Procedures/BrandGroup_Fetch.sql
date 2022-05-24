-- =============================================
-- Author:		JEA
-- Create date: 28/09/2012
-- Description:	Retrieves Brand Groups for the MIDI
-- Brand Group selection
-- =============================================
CREATE PROCEDURE [GAS].[BrandGroup_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;
	-- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
	SELECT CAST(BrandGroupID AS INT) AS BrandGroupID, CAST(BrandGroupID AS INT) AS Id, BrandGroupName
	FROM Relational.BrandGroup
	ORDER BY BrandGroupName
    
END