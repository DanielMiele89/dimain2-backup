-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_MaxFileIDProcessed_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT MAX(FileID) AS FileID FROM staging.CreditCardLoad_LastFileProcessed

END