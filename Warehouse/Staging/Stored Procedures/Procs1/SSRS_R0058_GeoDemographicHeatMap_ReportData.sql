

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/12/2014
-- Description: Collate customer counts per Partner for the Geodemographic Heatmap
--		Report
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0058_GeoDemographicHeatMap_ReportData]
			
AS
BEGIN
	SET NOCOUNT ON;


SELECT	PartnerID,
	PartnerName,
	[Less than 20],
	[Between 20 and 40],
	[Between 40 and 50],
	[Between 50 and 60],
	[Between 60 and 70],
	[Between 70 and 80],
	[Between 80 and 90],
	[Between 90 and 95],
	[Between 95 and 100],
	[Between 100 and 105],
	[Between 105 and 110],
	[Between 110 and 115],
	[Between 115 and 120],
	[Between 120 and 130],
	[Between 130 and 140],
	[Between 140 and 150],
	[Between 150 and 160],
	[Between 160 and 180],
	[Between 180 and 200],
	[Between 200 and 300],
	[Greater than 300]
FROM	(
SELECT	p.PartnerID,
	pa.PartnerName,
	r.ResponseIndexBand_Desc,
	COUNT(DISTINCT FanID) as CustomerCount
FROM Warehouse.relational.GeoDemographicHeatMap_Members m
INNER JOIN Warehouse.Relational.ResponseIndexBands_Description r
	ON m.ResponseIndexBand_ID = r.ResponseIndexBand_ID
INNER JOIN Warehouse.Relational.Partner_CBPDates p
	ON m.PartnerID = p.PartnerID
	AND (p.Scheme_EndDate IS NULL OR CAST(p.Scheme_EndDate AS DATE) >= CAST(GETDATE() AS DATE))
INNER JOIN Warehouse.Relational.Partner pa
	ON p.PartnerID = pa.PartnerID
WHERE m.EndDate IS NULL
GROUP BY p.PartnerID,pa.PartnerName,m.ResponseIndexBand_ID,r.ResponseIndexBand_Desc
	)a
PIVOT(
SUM(CustomerCount)
FOR ResponseIndexBand_Desc
IN (	[Less than 20],
	[Between 20 and 40],
	[Between 40 and 50],
	[Between 50 and 60],
	[Between 60 and 70],
	[Between 70 and 80],
	[Between 80 and 90],
	[Between 90 and 95],
	[Between 95 and 100],
	[Between 100 and 105],
	[Between 105 and 110],
	[Between 110 and 115],
	[Between 115 and 120],
	[Between 120 and 130],
	[Between 130 and 140],
	[Between 140 and 150],
	[Between 150 and 160],
	[Between 160 and 180],
	[Between 180 and 200],
	[Between 200 and 300],
	[Greater than 300]
))as pvt

END