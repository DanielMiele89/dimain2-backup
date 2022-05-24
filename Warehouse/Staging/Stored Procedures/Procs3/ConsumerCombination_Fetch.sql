-- =============================================
-- Author:		JEA
-- Create date: 12/12/2013
-- Description:	Sources the ConsumerTransaction Load
-- =============================================
CREATE PROCEDURE [Staging].[ConsumerCombination_Fetch] 
	(
		@FileID int
		, @MinRowNum int
		, @MaxRowNum int
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ct.FileID,
		ct.RowNum,
		ct.BrandMIDID,
		ct.BankID,
		ct.LocationAddress,
		ct.MCC,
		ct.CardholderPresentData,
		ct.TranDate,
		ct.CINID,
		ct.Amount,
		n.OriginatorID,
		n.PostStatus
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN Archive.dbo.NobleTransactionPreliminary n with (nolock) on ct.fileid = n.fileid and ct.RowNum = n.RowNum
	WHERE ct.FileID = @FileID
	AND ct.RowNum BETWEEN @MinRowNum AND @MaxRowNum
	AND BrandMIDID != 147179
	AND BrandMIDID != 142652

END