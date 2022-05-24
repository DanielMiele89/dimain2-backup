
-- =============================================
-- Author:		JEA
-- Create date: 11/10/2012
-- Description:	Creates a Brand
-- =============================================
CREATE PROCEDURE [gas].[Brand_Create]
	(
		@BrandName VARCHAR(50)
		, @IsLivePartner BIT
		, @BrandGroupID INT
		, @NarrativePrefix VARCHAR(50)
		, @BrandID INT OUTPUT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

   INSERT INTO Relational.Brand(BrandName, IsLivePartner, BrandGroupID)
   VALUES(@BrandName, @IsLivePartner, @BrandGroupID)
   
   SELECT @BrandID = SCOPE_IDENTITY()
   
   IF @NarrativePrefix IS NOT NULL AND @NarrativePrefix != ''
   BEGIN
		INSERT INTO Staging.BrandMatch(BrandID, Narrative)
		VALUES(@BrandID, @NarrativePrefix)
   END
   
END