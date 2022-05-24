
CREATE PROCEDURE [Staging].[SSRS_R0204_WebLoginStats]
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		DECLARE @StartDate DATE
			  , @EndDate DATE
			  , @MonthCount INT = 12

			 
		SELECT @StartDate = DATEADD(month, - (@MonthCount + 1), DATEADD(day, 1, EOMONTH(GETDATE(), -1)))
			 , @EndDate = EOMONTH(GETDATE(), -1)

	/*******************************************************************************************************************************************
		2. Fetch all Web Logins
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#WebLogins') IS NOT NULL DROP TABLE #WebLogins
		SELECT DATEADD(day, 1, EOMONTH(wl.TrackDate, -1)) AS TrackDate
			 , wl.FanID
		INTO #WebLogins
		FROM Relational.WebLogins wl
		WHERE TrackDate BETWEEN @StartDate AND @EndDate


	/*******************************************************************************************************************************************
		3. Aggregate to ClubId
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#LoginInfo') IS NOT NULL DROP TABLE #LoginInfo
		SELECT cu.ClubID
			 , wl.TrackDate
			 , COUNT(1) AS AllLogins
			 , COUNT(DISTINCT cu.FanID) AS UniqueCustomers
		INTO #LoginInfo
		FROM Relational.Customer cu
		INNER JOIN #WebLogins wl
			ON cu.FanID = wl.FanID
		GROUP BY cu.ClubID
			   , wl.TrackDate


	/*******************************************************************************************************************************************
		4. Output for report
	*******************************************************************************************************************************************/
	
		SELECT TrackDate
			 , MAX(CASE WHEN cl.Name = 'NatWest MyRewards' THEN AllLogins ELSE NULL END) AS NatWest_AllLogins
			 , MAX(CASE WHEN cl.Name = 'RBS MyRewards' THEN AllLogins ELSE NULL END) AS RBS_AllLogins
			 , MAX(CASE WHEN cl.Name = 'NatWest MyRewards' THEN UniqueCustomers ELSE NULL END) AS NatWest_UniqueCustomers
			 , MAX(CASE WHEN cl.Name = 'RBS MyRewards' THEN UniqueCustomers ELSE NULL END) AS RBS_UniqueCustomers
		FROM #LoginInfo li
		INNER JOIN SLC_Report..Club cl
			ON li.ClubID = cl.ID
		GROUP BY TrackDate
		ORDER BY TrackDate

END