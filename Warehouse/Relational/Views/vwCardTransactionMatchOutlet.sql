
create view [Relational].[vwCardTransactionMatchOutlet]
as

SELECT c.FileID, c.RowNum, h.MatchID, h.RetailOutletID, c.TranDate, c.InDate, c.CINID, c.CardholderPresentData, c.Amount
FROM Relational.CardTransaction c
INNER JOIN Archive.dbo.NobleTransactionHistory h on c.FileID = h.FileID and c.RowNum = h.RowNum
