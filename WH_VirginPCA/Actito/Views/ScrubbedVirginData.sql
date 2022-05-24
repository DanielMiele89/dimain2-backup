CREATE VIEW [Actito].[ScrubbedVirginData]
AS
SELECT	FanID
	,	ROW_NUMBER() OVER (ORDER BY FanID) AS NewFanID
	,	'' AS NewSourceUID
	,	180 AS ClubID
	,	'EmailAddress' + CONVERT(VARCHAR(10), ROW_NUMBER() OVER (ORDER BY FanID)) + '@RewardInsight.com' AS NewEmail
	,	'FirstName' + CONVERT(VARCHAR(10), ROW_NUMBER() OVER (ORDER BY FanID)) AS NewFirstName
	,	'LastName' + CONVERT(VARCHAR(10), ROW_NUMBER() OVER (ORDER BY FanID)) AS NewLasName
	,	'2000-01-01' AS NewDOB
	,	CASE
			WHEN ROW_NUMBER() OVER (ORDER BY FanID) % 2 = 0 THEN 'M'
			ELSE 'F'
		END AS NewGender
	,	PostCodeDistrict AS NewPartialPostCode
FROM [WH_Virgin].[Derived].[Customer]
