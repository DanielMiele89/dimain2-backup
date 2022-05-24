
CREATE VIEW [MI].[vwPartnerAlternate]
WITH SCHEMABINDING
AS

SELECT p.PartnerID AS PartnerMatchID
	, p.PartnerID
	, PartnerName
	, p.BrandID
FROM Relational.[Partner] p
LEFT OUTER JOIN APW.PartnerAlternate a ON P.PartnerID = A.PartnerID
WHERE A.PartnerID IS NULL

UNION ALL

SELECT a.PartnerID AS PartnerMatchID
	, p.PartnerID
	, PartnerName
	, p.BrandID
FROM Relational.[Partner] p
INNER JOIN APW.PartnerAlternate a ON P.PartnerID = A.AlternatePartnerID