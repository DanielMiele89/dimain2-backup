-- =============================================
-- Author:		JEA
-- Create date: 31/10/2016
-- Description:	slc_report staging customer load
-- =============================================
CREATE PROCEDURE [APW].[DirectLoad_Staging_Customer_Fetch]
AS
BEGIN

	SET NOCOUNT ON;

	SELECT f.ID AS FanID,
		f.[Status] AS CustStatus,
		f.dob AS DOB,
		CAST(COALESCE(ca.ActivatedDate, pa.AgreedTCs,f.AgreedTCsDate) AS DATE) AS ActivatedDate,		--Date Activated
		CAST(CASE f.Sex WHEN 1 THEN 'M'
				When 2 THEN 'F'
				ELSE 'U'
			 END AS CHAR(1)) AS Gender,
		CASE
			WHEN f.[Status] = 0 OR f.AgreedTCs = 0 OR f.AgreedTCsDate IS NULL THEN COALESCE(ca.OptedOutDate,ca.DeactivatedDate)
			ELSE NULL
		END AS DeactivatedDate	
	FROM SLC_Report.dbo.Fan f
			LEFT OUTER JOIN (SELECT FANID,[Date] AS AgreedTCs
				from Staging.InsightArchiveData as iad
				WHERE iad.TypeID = 1) pa
				ON f.ID = pa.FanID
			LEFT OUTER JOIN MI.CustomerActiveStatus ca
				ON f.ID = ca.FanID
			LEFT OUTER JOIN Staging.Customer_TobeExcluded ctbe ON f.ID = ctbe.FanID
	WHERE f.ClubID IN (132,138) AND (f.AgreedTCs = 1 OR NOT(pa.AgreedTCs IS null))
		AND f.ID NOT IN (19587579)
		AND ctbe.FanID IS NULL

END