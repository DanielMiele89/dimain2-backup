-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets bank IDs on transactions in the holding area
-- =============================================
CREATE PROCEDURE [gas].[HoldingSetBankID]
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.CardTransactionHolding SET BankID = b.bankid
	FROM Staging.CardTransactionHolding h WITH (NOLOCK)
	INNER JOIN Relational.CardTransactionBank b WITH (NOLOCK) on h.BankIDString = b.BankIdentifier
	
	UPDATE Staging.CardTransactionHolding SET IsOnline = 0, IsRefund = 0
	
	UPDATE Staging.CardTransactionHolding SET IsOnline = 1
	WHERE CardholderPresentData = '5'
	
	UPDATE Staging.CardTransactionHolding SET IsRefund = 1
	WHERE Amount < 0

	UPDATE Staging.CardTransactionHolding SET MCCID = m.MCCID
	FROM Staging.CardTransactionHolding h
	INNER JOIN Relational.MCCList m ON h.MCC = m.MCC

	UPDATE Staging.CardTransactionHolding SET CardholderPresentID = CAST(CardholderPresentData AS TINYINT)

	INSERT INTO Relational.MCCList(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT DISTINCT MCC, '', '', '', 1
	FROM Staging.CardTransactionHolding
	WHERE MCCID IS NULL

	UPDATE Staging.CardTransactionHolding SET MCCID = m.MCCID
	FROM Staging.CardTransactionHolding h
	INNER JOIN Relational.MCCList m ON h.MCC = m.MCC
	WHERE h.MCCID IS NULL

	UPDATE Staging.CardTransactionHolding SET PostStatusID = p.PostStatusID
	FROM Staging.CardTransactionHolding H
	INNER JOIN Relational.PostStatus p ON h.PostStatus = p.PostStatusDesc
	
END