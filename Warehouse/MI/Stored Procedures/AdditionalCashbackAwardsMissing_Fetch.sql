-- =============================================
-- Author:		JEA
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.AdditionalCashbackAwardsMissing_Fetch

AS
BEGIN

	SET NOCOUNT ON;

    SELECT CAST(AdditionalCashbackAwardTypeID AS tinyint) AS AdditionalCashbackAwardTypeID
		, Title AS AwardTitle
		, [Description] AS AwardDescription
	FROM Relational.AdditionalCashbackAwardType
	WHERE AdditionalCashbackAwardTypeID NOT IN (12,13,14,15,16,17,18,19) -- Apply pay adjustment duplication

END