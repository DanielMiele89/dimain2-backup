-- =============================================
-- Author:		JEA
-- Create date: 04/02/2013
-- Description:	Displays those MIDS matched by MIDI to a live partner
-- =============================================
CREATE PROCEDURE gas.LivePartnerMIDReview 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT b.BrandName as Brand, l.MID, l.Narrative, l.[Address], l.MCC, l.MCCDesc as [MCC Description]
	, CASE WHEN o.MerchantID IS NULL THEN 'Not in GAS' ELSE 'In GAS' END AS MIDStatus
	FROM staging.LivePartnerReview l
	INNER JOIN Relational.BrandMID bm on l.BrandMIDID = bm.BrandMIDID
	INNER JOIN Relational.Brand b on bm.BrandID = b.BrandID
	LEFT OUTER JOIN Relational.[Partner] p on b.BrandID = p.BrandID
	LEFT OUTER JOIN Relational.Outlet o on p.PartnerID = o.PartnerID and l.MID = o.MerchantID
	ORDER BY Brand, MID

END

GO
GRANT EXECUTE
    ON OBJECT::[gas].[LivePartnerMIDReview] TO [DB5\reportinguser]
    AS [dbo];

