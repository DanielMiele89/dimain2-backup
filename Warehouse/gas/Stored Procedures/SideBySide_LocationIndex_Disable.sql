-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	disables the index on relational.location
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_LocationIndex_Disable]
	
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_Relational_Location_Cover ON Relational.Location DISABLE


END
