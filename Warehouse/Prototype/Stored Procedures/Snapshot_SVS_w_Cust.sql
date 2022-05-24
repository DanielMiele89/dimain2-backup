-- =============================================
-- Author:		<Snapshot - 13 Months SVS with Customer Count>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE Prototype.Snapshot_SVS_w_Cust 
	(
		@Population VARCHAR(100),
		@CC VARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population 
		(
			CINID INT
		)
	EXEC	('	
				INSERT INTO #Population
					SELECT	CINID
					FROM	' + @Population +' pop
			')
	CREATE CLUSTERED INDEX cix_CINID ON #Population(CINID)

	IF OBJECT_ID('tempdb..#ConsumerCombinationIDs') IS NOT NULL DROP TABLE #ConsumerCombinationIDs
	CREATE TABLE #ConsumerCombinationIDs
		(
			BrandID INT,
			BrandName VARCHAR(50),
			ConsumerCombinationID INT
		)
	EXEC	('
				INSERT INTO #ConsumerCombinationIDs
					SELECT	BrandID,
							BrandName,
							ConsumerCombinationID
					FROM	' + @CC + '
			')

	SELECT	*
	FROM	#ConsumerCombinationIDs
END