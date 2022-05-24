-- =============================================
-- Author:		JEA
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Prototype.OPEBrandRatio_Refresh
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @StartDate DATE, @EndDate DATE

	--set the end date to the Monday of last week
	SET @EndDate = DATEADD(DAY, -6, DATEADD(D, -1, DATEADD(WK, DATEDIFF(WK, 0, GETDATE()), 0)))
	SET @StartDate = DATEADD(DAY, -13, @EndDate)

	CREATE TABLE #combos(consumercombinationid int primary key, brandid smallint not null)

	INSERT INTO #combos(consumercombinationid,brandid)
	SELECT c.consumercombinationid, c.brandid
	FROM Relational.ConsumerCombination c
	INNER JOIN (SELECT DISTINCT brandid FROM Prototype.OPECustomerPropensity_Stage) b ON c.brandid = b.brandid

	CREATE TABLE #spenders(id INT PRIMARY KEY IDENTITY
	, cinid INT NOT NULL
	, brandid SMALLINT NOT NULL)

	INSERT INTO #spenders(cinid, brandid)
	SELECT ct.CINID, c.brandid
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #combos c on ct.ConsumerCombinationID = c.consumercombinationid
	WHERE ct.TranDate BETWEEN @StartDate and @EndDate

	UNION

	SELECT ct.CINID, c.brandid
	FROM Relational.ConsumerTransaction_CreditCard ct WITH (NOLOCK)
	INNER JOIN #combos c on ct.ConsumerCombinationID = c.consumercombinationid
	WHERE ct.TranDate BETWEEN @StartDate and @EndDate

	TRUNCATE TABLE Prototype.OPESpender

	INSERT INTO prototype.OPESpender(id, BrandID, CINID)
	SELECT p.ID, p.BrandID, p.CINID
	FROM Prototype.OPECustomerPropensity_Stage p
	INNER JOIN #spenders s ON p.BrandID = s.brandid AND p.CINID = s.cinid

	CREATE TABLE #PropSpend(ID int primary key identity
	, BrandID smallint not null
	, PropClass tinyint not null
	, CustomerCount float not null
	, PropTotal float not null
	, SpenderTotal float not null)

	INSERT INTO #PropSpend(BrandID, PropClass, CustomerCount, PropTotal, SpenderTotal)
	SELECT p.BrandID
		, p.PropClass
		, COUNT(distinct p.cinid) as CustomerCount
		, ISNULL(SUM(p.Propensity),0) as PropTotal
		, ISNULL(SUM(s.spend),0) as SpenderTotal
	FROM Prototype.OPECustomerPropensity_Stage p
	LEFT OUTER JOIN (SELECT brandid, cinid, CAST(1 AS FLOAT) AS spend FROM Prototype.OPESpender) s ON p.BrandID = s.BrandID and p.CINID = s.CINID
	GROUP BY p.BrandID, p.PropClass

	TRUNCATE TABLE Prototype.OPEBrandRatio

	;WITH ps (BrandID, PropClass, CustomerCount, PropTotal, SpenderTotal, PropMean, SpenderMean, Ratio)
	AS
	(
		SELECT BrandID, PropClass, CustomerCount, PropTotal, SpenderTotal
			, PropTotal/NULLIF(CustomerCount,0) AS PropMean, SpenderTotal/NULLIF(CustomerCount,0) AS SpenderMean, PropTotal/NULLIF(SpenderTotal,0) AS Ratio
		FROM #PropSpend
	)
	INSERT INTO Prototype.OPEBrandRatio(BrandID, PropClass, Ratio)

	SELECT ps.BrandID, ps.PropClass, COALESCE(ps.Ratio, l.LowerRatio, h.HigherRatio, m.MaxRatio,100000) AS RatioUsed
	FROM ps 
	LEFT OUTER JOIN (Select BrandID, PropClass -1 as PropClass, Ratio AS LowerRatio FROM ps) l on ps.brandid = l.brandid and ps.propclass = l.PropClass
	LEFT OUTER JOIN (Select BrandID, PropClass +1 as PropClass, Ratio AS HigherRatio FROM ps) h on ps.brandid = h.brandid and ps.propclass = h.PropClass
	LEFT OUTER JOIN (Select BrandID, MAX(Ratio) AS MaxRatio FROM ps GROUP BY Brandid) m on ps.brandid = m.brandid
	ORDER BY ps.brandid, ps.propclass

END
