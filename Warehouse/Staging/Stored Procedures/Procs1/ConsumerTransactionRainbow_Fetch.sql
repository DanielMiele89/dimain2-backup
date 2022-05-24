-- =============================================
-- Author:		JEA
-- Create date: 12/12/2013
-- Description:	Sources the ConsumerTransaction Load
-- =============================================
CREATE PROCEDURE [Staging].[ConsumerTransactionRainbow_Fetch] 

	(
		@FileID INT
		, @StartID INT
		, @EndID INT
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
	INNER JOIN Archive.dbo.NobleRainbowTransactionPreliminary n with (nolock) on ct.fileid = n.fileid and ct.RowNum = n.RowNum
	WHERE ct.FileID = @FileID
	AND ct.RowNum BETWEEN @StartID AND @EndID
	AND BrandMIDID != 147179
	AND BrandMIDID != 142652
	ORDER BY FileID

END
