CREATE PROCEDURE dbo.PRTG_CongestionChecker AS 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	[CollectionLag] 
FROM (
	SELECT LastCollection = MAX([collection_time])
	FROM [Monitor].[dbo].[WhoIsActive] 
) d
CROSS APPLY (SELECT [CollectionLag] = DATEDIFF(MINUTE, LastCollection, GETDATE())) x

RETURN 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PRTG_CongestionChecker] TO [PRTGBuddy]
    AS [dbo];

