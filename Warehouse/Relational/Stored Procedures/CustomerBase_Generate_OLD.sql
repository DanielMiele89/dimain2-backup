-- =============================================
-- Author:		JEA
-- Create date: 24/05/2013
-- Description:	Generates a dynamically named
-- table containing all of the CINIDs for customers
-- who have been actively using their card for retail
-- purchases over a specified period
-- =============================================
CREATE PROCEDURE [Relational].[CustomerBase_Generate_OLD] 
	(
		@TableName Varchar(50)  --the name of the table to be created in InsightArchive
		, @StartDate date --the beginning of the date range
		, @EndDate date --the end of the date range
		, @IncludeUnsafe bit = 0 --by default, only bankID 2 is included before 01 October 2013
		, @AcceptDefaults bit = 0
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @sql varchar(8000), @KeepValues varchar(50) = '%[^a-z,_,0-9]%'
		, @TransTestStart date, @TransTestEnd date, @WeekCount SmallInt, @OriginalTableName varchar(50)
	
	BEGIN TRY
	
		--**VALIDATION SECTION BEGINS**
	
		SET @OriginalTableName = @TableName
	
		--Strip non-alpha characters from the table name, i.e. prevent sql injection or illegal table names
		WHILE PatIndex(@KeepValues, @TableName) > 0
			SET @TableName = Stuff(@TableName, PatIndex(@KeepValues, @TableName), 1, '')
	    
	    --If any illegal characters have been used, warn the user and stop the process
	    IF @TableName != @OriginalTableName
	    BEGIN
			RAISERROR('Tables can only be named with alphanumeric and underscore characters', 16,1)
	    END
	    
		--The name listed will be used to create a table in the InsightArchive schema
		--Check that a table of this name does not exist already    
		IF EXISTS(SELECT * FROM sys.tables t
			INNER JOIN sys.schemas s on t.schema_id = s.schema_ID
			WHERE s.name = 'InsightArchive'
			AND T.name = @TableName)
		BEGIN
			RAISERROR('This table already exists in InsightArchive', 16,1)
		END
		
		--Check that the start date is 01 July 2011 or later
		--Data is not held before this date so sampling would be invalid
		IF @StartDate < '2011-07-01'
		BEGIN
			IF @AcceptDefaults = 1
			BEGIN
				SET @StartDate = '2011-07-01'
			END
			ELSE
			BEGIN
				RAISERROR('Start date is too early', 16,1)
			END
		END

		--Check that the end date is at least a week old
		--This allows time for transactions to be received and populated into the data warehouse
		IF @EndDate > DATEADD(WEEK, -1, GETDATE())
		BEGIN
			IF @AcceptDefaults = 1
			BEGIN
				SET @EndDate = DATEADD(WEEK, -1, GETDATE())
			END
			ELSE
			BEGIN
				RAISERROR('End date is too late', 16,1)
			END
		END
		
		--Check that the end date at least a week later than the start date
		IF @EndDate < DATEADD(WEEK, 1, @StartDate)
		BEGIN
			RAISERROR('End date should be at least a week later than start date', 16,1)
		END

		DECLARE @StartDateIsUnsafe bit = 0

		IF @StartDate < '2012-10-22' AND @IncludeUnsafe = 0
		BEGIN
			SET @StartDateIsUnsafe = 1
		END
		
		--**VALIDATION SECTION ENDS**

		--Create table to store the customer base CINIDs in the InsightArchive schema
		SET @sql = 'CREATE TABLE InsightArchive.' + @TableName +'(CINID INT NOT NULL)'
		
		EXEC(@sql)
		
		--set the transaction test variables to the correct values to assess continuous card use before and after the specified period
		--for particularly early start dates, allow a month of data gathering
		IF @StartDate < '2011-08-01'
			BEGIN
				SET @TransTestStart = '2011-08-01'
			END
		ELSE
			BEGIN
				SET @TransTestStart = @StartDate
			END
		
		--for particularly recent end dates, allow a month of data gathering
		IF @EndDate > DATEADD(MONTH, -1,DATEADD(WEEK, -1, GETDATE()))
			BEGIN
				SET @TransTestEnd = DATEADD(MONTH, -1,DATEADD(WEEK, -1, GETDATE()))
			END
		ELSE
			BEGIN
				SET @TransTestEnd = @EndDate
			END
		
		--Create a temp table to test eligible customer transaction counts
		CREATE TABLE #CustBaseTest(CINID INT NOT NULL, TranCount INT NULL)
		
		--Load the temp table with the CINIDs of customers who pass the start and end date tests
		INSERT INTO #CustBaseTest(CINID)
		SELECT CINID
		FROM Relational.CustomerAttribute c
		INNER JOIN Relational.CardTransactionBank b on c.BankID = B.BankID
		WHERE (@StartDateIsUnsafe = 0 OR (b.IsRainbow = 0 AND b.IsRBS = 0)) --NatWest customers only unless override has been specified
		AND FirstTranDate < @TransTestStart -- check that a transaction was made before the start date ***NB - OPTED OUT CUSTOMERS WILL NOT HAVE A FirstTranDate OR Recency DATES***
		AND (RecencyOnline > @TransTestEnd OR RecencyOffline > @TransTestEnd) -- check that an online or offline transaction was made after the end date
		
		--Add a primary key to assist the gathering of trans count data
		ALTER TABLE #CustBaseTest ADD PRIMARY KEY(CINID)
		
		--Obtain the tran count for the customers - WARNING: this is the most intensive part of the process because of the size of CardTransaction
		UPDATE #CustBaseTest SET TranCount = t.TranCount
		FROM #CustBaseTest c
		INNER JOIN (SELECT C.CINID, COUNT(1) AS TranCount
					FROM Relational.CardTransaction C WITH (NOLOCK)
					INNER JOIN Relational.BrandMIDSector BMS ON C.BrandMIDID = BMS.BrandMIDID  --Only retail transactions are to be counted
					WHERE TranDate BETWEEN @StartDate AND @EndDate
					GROUP BY CINID) t ON c.CINID = t.CINID
					
		--Calculate number of weeks.  Eligible customers should have at least this number of transactions in the period
		SET @WeekCount = DATEDIFF(WEEK, @StartDate, @EndDate)
		
		--Insert customers who pass the transaction count test into the table in the InsightArchive schema
		SET @sql = 'INSERT INTO InsightArchive.' + @TableName + '(CINID) SELECT CINID FROM #CustBaseTest WHERE TranCount >= ' + CAST(@WeekCount AS VARCHAR(20))
		
		EXEC(@sql)
		
		--Add a primary key to the table (wait until data is inserted to avoid fragmentation
		SET @sql = 'ALTER TABLE InsightArchive.' + @TableName + ' ADD PRIMARY KEY(CINID)'
		
		EXEC(@sql)
		
		--inform the user that the operation was successful
		PRINT 'Table InsightArchive.' + @TableName + ' created and loaded successfully.'
		
	END TRY
	
	BEGIN CATCH
		--Display error message to user
		PRINT ERROR_MESSAGE()
	END CATCH
   
END
