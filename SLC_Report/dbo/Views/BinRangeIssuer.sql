
CREATE VIEW [dbo].[BinRangeIssuer] AS
SELECT ID, BinRange, Scheme, Issuer, CardType, CardSubType, Country, Telephone
FROM SLC_Snapshot.dbo.BinRangeIssuer

GO
GRANT SELECT
    ON OBJECT::[dbo].[BinRangeIssuer] TO [Analyst]
    AS [dbo];

