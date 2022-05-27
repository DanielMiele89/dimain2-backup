-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.PJ_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	-- Getting those who are 18-34 years of age
	-- Get customers, add columns as needed
	CREATE TABLE #BaseCustomers (fanid INT NOT NULL
		 ,cinid INT NOT NULL
		 ,Gender VARCHAR(1)
		 ,PostalSector varchar(30)
		 ,Age_Group Varchar(12)
		 ,AgeCurrent int
		 ,CAMEO_CODE_GRP VARCHAR(50)
		 ,Region VARCHAR(25)
		 ,MarketableByEmail TINYINT
		 ,Family varchar(30)
		 ,HighDM varchar(30)
		 ,Age1834 varchar(30)
		 ,PJspender varchar(30)
		 ,COMPspender varchar(30))
     

	-- Fill table with chunk sizing
	DECLARE @MinID INT, @MaxID INT, @Increment INT = 500000, @MaxIDValue INT
	SELECT @MaxIDValue = MAX(FanID) FROM Relational.Customer
	SET @MinID = 1
	SET @MaxID = @Increment

	WHILE @MinID < @MaxIDValue
	BEGIN

	 INSERT INTO #BaseCustomers
	 SELECT      
		c.FanID
		,cl.cinid
		,c.Gender
		,c.PostalSector
		,CASE  
		   WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
		   WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
		   WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
		   WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
		   WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
		   WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
		   WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
		   WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
		END as Age_Group,
		c.AgeCurrent
		,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') 
		,c.Region
		,c.MarketableByEmail
		,cast(NULL as varchar(30)) as Family
		,cast(NULL as varchar(30)) as HighDM
		,cast(NULL as varchar(30)) as Age1834
		,cast(NULL as varchar(30)) as PJspender
		,cast(NULL as varchar(30)) as COMPspender


	 FROM Warehouse.Relational.Customer c  WITH (NOLOCK)
	 LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
	  ON c.PostCode = cam.Postcode
	 LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
	  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
	 INNER JOIN warehouse.relational.CINList as cl 
	  ON c.SourceUID=cl.CIN
	 inner join warehouse.mi.customeractivationperiod cap on cap.fanid = c.fanid
	 WHERE 
	 c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
	 and c.fanID between @MinID and @MaxID
	 and c.currentlyactive = 1


	 SET @MinID = @MinID + @Increment
	 SET @MaxID = @MaxID + @Increment

	END


	-- Dominos, Pizza Hut, Just Eat
	if object_id('tempdb..#CCs') is not null drop table #CCs
	select ConsumerCombinationID
	into #CCs
	from relational.consumercombination cc
	where
	cc.brandid in (129, 1122, 337)


	declare @Today date = getdate()
	declare @YearAgo date = dateadd(year, -1,@Today)

	-- Get the comp spenders
	if object_id('tempdb..#CompSpenders') is not null drop table #CompSpenders
	select distinct ct.CINID, c.FanID
	into #CompSpenders
	from #CCs cc
	inner join relational.consumertransaction ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
	inner join Relational.cinlist cl on cl.CINID = ct.CINID
	inner join relational.customer c on c.sourceuid = cl.CIN
	where
	trandate between @YearAgo and @Today



	-- Update the COMspenders
	update t
	set COMPspender = case when cp.cinid is null then 'No' else 'Yes' end
	from #BaseCustomers t
	left join #CompSpenders cp on cp.cinid = t.cinid


	-- Update the Family
	update t
	set Family = case when ca.cinid is null then 'No'
		  when ca.Parent = 1 then 'Yes'
		  else 'No' end 
	from #BaseCustomers t
	left join Relational.CustomerAttribute ca on ca.CINID = t.cinid



	-- Insert into the table
	select CINID, fanid
	into #FinalSelection
	from #BaseCustomers
	where
	Family = 'Yes' or
	COMPspender = 'Yes' or
	AgeCurrent between 18 and 34 or
	CAMEO_CODE_GRP in ('01-Business Elite','02-Prosperous Professionals','03-Flourishing Society')


	If object_id('Warehouse.Selections.PJ_PreSelection') is not null drop table Warehouse.Selections.PJ_PreSelection
	Select FanID
	Into Warehouse.Selections.PJ_PreSelection
	From #FinalSelection

END


