
CREATE VIEW [dbo].[BinRange] AS
SELECT ID, Name, BinStart, BinEnd, RangeSize, Valid, DisplayName, Scheme, PayPointName, Logo, CreditOrDebit, SchemeId
FROM SLC_Snapshot.dbo.BinRange

GO
GRANT SELECT
    ON OBJECT::[dbo].[BinRange] TO [Analyst]
    AS [dbo];

