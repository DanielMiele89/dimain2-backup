-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Resolves paypal secondary ids
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_PaypalSecondaryIDs_Set_DIMAIN] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--set existing secondary combinations
	UPDATE s 
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP(1) PaymentGatewayID 
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
			AND s.MID = p.MID
			AND s.Narrative = p.Narrative
		ORDER BY PaymentGatewayID DESC
	) p

	--insert new secondary combinations
	INSERT INTO Relational.PaymentGatewaySecondaryDetail 
		(ConsumerCombinationID, MID, Narrative)
	SELECT DISTINCT -- resolves dupe issue 
		ConsumerCombinationID, MID, Narrative
	FROM Staging.CTLoad_PaypalSecondaryID WITH (TABLOCK)
	WHERE SecondaryCombinationID IS NULL

	--update rows with newly inserted IDs
	UPDATE s 
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_PaypalSecondaryID s WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP(1) PaymentGatewayID 
		FROM Relational.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
			AND s.MID = p.MID
			AND s.Narrative = p.Narrative
		ORDER BY PaymentGatewayID DESC
	) p
	WHERE s.SecondaryCombinationID IS NULL

	--update staging table with secondary IDs
	UPDATE i
		SET SecondaryCombinationID = p.SecondaryCombinationID
	FROM Staging.CTLoad_InitialStage i WITH (TABLOCK)
	INNER JOIN Staging.CTLoad_PaypalSecondaryID p 
		ON i.FileID = p.FileID AND i.RowNum = p.RowNum


	TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID

END