-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Resolves paypal secondary ids
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_PaypalSecondaryIDs_Set_20211210] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--set existing secondary combinations
	UPDATE Staging.CTLoad_PaypalSecondaryID SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON 
		s.ConsumerCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative

	--disable index prior to insert
	ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

	--insert new secondary combinations
	INSERT INTO Relational.PaymentGatewaySecondaryDetail(ConsumerCombinationID, MID, Narrative)
	SELECT ConsumerCombinationID, MID, Narrative
	FROM Staging.CTLoad_PaypalSecondaryID
	WHERE SecondaryCombinationID IS NULL

	--rebuild index following insert for subsequent querying
	ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

	--update rows with newly inserted IDs
	UPDATE Staging.CTLoad_PaypalSecondaryID SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON 
		s.ConsumerCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative
	WHERE s.SecondaryCombinationID IS NULL

	--update staging table with secondary IDs
	UPDATE i
	SET SecondaryCombinationID = p.SecondaryCombinationID
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN Staging.CTLoad_PaypalSecondaryID p ON i.FileID = p.FileID AND i.RowNum = p.RowNum

	TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID

END
