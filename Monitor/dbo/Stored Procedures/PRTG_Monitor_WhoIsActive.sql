CREATE PROCEDURE dbo.PRTG_Monitor_WhoIsActive AS 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	[Collection_Time], 
	[CollectionLag] = ABS(DATEDIFF(MINUTE,LAG([collection_time],1) OVER(ORDER BY [collection_time]),[collection_time]) - 10)
FROM (
	SELECT [collection_time]
	FROM [Monitor].[dbo].[WhoIsActive] 
	GROUP BY [collection_time]
) d
ORDER BY [collection_time] DESC

RETURN 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_Monitor_WhoIsActive] TO [PRTGBuddy]
    AS [dbo];

