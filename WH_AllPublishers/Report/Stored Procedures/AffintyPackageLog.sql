



CREATE PROCEDURE [Report].[AffintyPackageLog]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT *
  FROM [Affinity].[Processing].[vw_PackageLog]

END
