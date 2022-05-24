-- =============================================
-- Author:		<Snapshot - 13 Months SVS with Customer Count>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_0_Test]
	(
		@Population VARCHAR(100),
		@Trans VARCHAR(100),
		@CC VARCHAR(100),
		@EndDate DATE
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChildStartDate DATE = DATEADD(MONTH,-6,DATEADD(DAY,1,@EndDate))
	DECLARE @EndDateVARCHAR VARCHAR(10) = CAST(@EndDate AS VARCHAR(10))
	DECLARE @ChildStartDateVARCHAR VARCHAR(10) = CAST(@ChildStartDate AS VARCHAR(10))

	IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID
	CREATE TABLE #CINID 
		(
			CINID INT
		)
	EXEC	('	
				INSERT INTO #CINID
					SELECT	CINID
					FROM	' + @Population +' pop
			')
	CREATE CLUSTERED INDEX cix_CINID ON #CINID(CINID)

	DECLARE @PopnCount INT = (SELECT COUNT(*) FROM #CINID)

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
	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #ConsumerCombinationIDs(ConsumerCombinationID)

	
	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
	CREATE TABLE #Transactions 
		(
			CINID INT,
			ConsumerCombinationID INT,
			Amount MONEY,
			IsOnline BIT,
			TranDate DATE
		)
	EXEC	('	
				INSERT INTO #Transactions
					SELECT	CINID,
							ConsumerCombinationID,
							Amount,
							IsOnline,
							TranDate
					FROM	' + @Trans + '
					WHERE	''' + @ChildStartDateVARCHAR + ''' <= TranDate AND TranDate <= ''' + @EndDateVARCHAR + '''
			')

	CREATE CLUSTERED INDEX CIX_Trans_TranDate ON #Transactions(TranDate)
	CREATE NONCLUSTERED INDEX NIX_Trans_TranDateCINID ON #Transactions(TranDate) INCLUDE (CINID)
	CREATE NONCLUSTERED INDEX NIX_Trans_ConsumerCombinationIDCINID ON #Transactions(ConsumerCombinationID) INCLUDE (CINID)

	SELECT		MIN(TranDate)
				,MAX(TranDate)
	FROM		#Transactions

END