-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Resolves paypal secondary ids
-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_PaypalSecondaryIDs_Set] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--set existing secondary combinations
	UPDATE s 
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s WITH (TABLOCK)
	CROSS APPLY (
		SELECT TOP(1) p.PaymentGatewayID 
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
			AND s.MID = p.MID
			AND s.Narrative = p.Narrative
		ORDER BY p.PaymentGatewayID DESC
	) p

	--insert new secondary combinations
	INSERT INTO Relational.PaymentGatewaySecondaryDetail
		(ConsumerCombinationID, MID, Narrative)
	SELECT DISTINCT -- avoid dupes CJM
		ConsumerCombinationID, MID, Narrative
	FROM Staging.CTLoad_PaypalSecondaryID
	WHERE SecondaryCombinationID IS NULL
	ORDER BY ConsumerCombinationID, MID, Narrative

	--update rows with newly inserted IDs
	UPDATE s 
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s WITH (TABLOCK)
	CROSS APPLY (
		SELECT TOP(1) p.PaymentGatewayID
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
			AND s.MID = p.MID
			AND s.Narrative = p.Narrative
		ORDER BY p.PaymentGatewayID DESC
	) p
	WHERE s.SecondaryCombinationID IS NULL

	--update staging table with secondary IDs
	UPDATE i
		SET SecondaryCombinationID = p.SecondaryCombinationID
	FROM Staging.CreditCardLoad_InitialStage i WITH (TABLOCK)
	INNER JOIN Staging.CTLoad_PaypalSecondaryID p 
		ON i.FileID = p.FileID AND i.RowNum = p.RowNum

	TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID

END

RETURN 0