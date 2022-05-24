-- ==============================================================================================
-- Author:		<Ijaz Amjad>
-- Create date: <09/03/2016>
-- Description:	<This stored procedure is used to populate the report PartnerOutletValidationBPD>
--               Pulls back all MIDs for that brand in BPD.
-- ==============================================================================================
CREATE PROCEDURE [Prototype].[PartnerOutletValidationBPD]	@BrandID int,
															@LocationCountry varchar(3)
AS
BEGIN
SELECT		DISTINCT
			b.BrandName,
			cc.MID,
			cc.Narrative,
			cc.MCCID,
			mcc.MCCDesc,
			cc.OriginatorID,
			cc.LocationCountry
FROM		[Warehouse].[Relational].[Brand] AS b
INNER JOIN	[Warehouse].[Relational].[ConsumerCombination] AS cc
ON			b.BrandID = cc.BrandID
INNER JOIN	[Warehouse].[Relational].[MCCList] AS mcc
ON			cc.MCCID = mcc.MCCID
WHERE		b.BrandID = @BrandID
	AND		(REPLACE(cc.LocationCountry, ' ','') = @LocationCountry
	OR		@LocationCountry = '')
GROUP BY	b.BrandName,
			cc.MID,
			cc.Narrative,
			cc.MCCID,
			mcc.MCCDesc,
			cc.OriginatorID,
			cc.LocationCountry
ORDER BY	cc.MID
END