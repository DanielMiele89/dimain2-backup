

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 01/09/2016													  --
-- Description: Shows the tracking status of retailers						  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0130_DisplayRetailer_Tracking]
				@IsTrackable varchar(4)
AS


SELECT			b.BrandID
,				b.BrandName
,				CASE
					WHEN tr.PartnerID IS NULL THEN ''
					ELSE tr.PartnerID
				END AS PartnerID
,				CASE
					WHEN tr.PartnerName IS NULL THEN ''
					ELSE tr.PartnerName
				END AS PartnerName
,				a.AcquirerName
,				tr.Trackable
FROM			Staging.TrackableRetailers AS tr
INNER JOIN		Relational.Brand AS b
		ON		tr.BrandID = b.BrandID
INNER JOIN		Relational.Acquirer AS a
		ON		tr.AcquirerID = a.AcquirerID
WHERE			tr.Trackable = @IsTrackable or @IsTrackable = 'Both'
ORDER BY		b.BrandName