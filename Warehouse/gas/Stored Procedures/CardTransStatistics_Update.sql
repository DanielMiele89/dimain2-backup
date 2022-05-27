-- =============================================
-- Author:		JEA
-- Create date: 22/01/2013
-- Description:	Updates statistics on largest
-- target tables because this will not be triggered
-- by the size of the load
-- =============================================
CREATE PROCEDURE [gas].[CardTransStatistics_Update] 
WITH EXECUTE AS OWNER
AS
BEGIN
	
	UPDATE STATISTICS Relational.CardTransaction
	UPDATE STATISTICS Relational.BrandMID
END
