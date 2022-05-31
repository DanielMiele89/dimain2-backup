
	CREATE PROCEDURE [WilliamA].[BrandAuditReview] @BrandNameSearch VARCHAR(50)
	AS


	--DECLARE @BrandNameSearch VARCHAR(50) = 'Tesco'
	
	DECLARE @BrandID INT
	select @BrandID = BrandID
	from Warehouse.Relational.Brand b 
	where BrandName IN (@BrandNameSearch)

	IF OBJECT_ID('tempdb..#AllCombosCounts') IS NOT NULL DROP TABLE #AllCombosCounts
	; WITH MyRewardCombos as (
		select brandid,narrative,locationCountry,MCCID,count(*) as ComboCount
		from Warehouse.Relational.ConsumerCombination
		where Narrative != ''
		AND MID !=''
		group by  brandid,narrative,locationCountry,MCCID
	), VirginCombos as (
		select brandid,narrative,locationCountry,MCCID,count(*) as ComboCount
		from WH_Virgin.Trans.ConsumerCombination
		where Narrative != ''
		AND MID !=''
		group by  brandid,narrative,locationCountry,MCCID
	), VisaCombos as (
		select brandid,narrative,locationCountry,MCCID,count(*) as ComboCount
		from WH_Visa.Trans.ConsumerCombination
		where Narrative != ''
		AND MID !=''
		group by  brandid,narrative,locationCountry,MCCID
	), AllCombos as (
		select *
		from MyRewardCombos
		UNION ALL
		SELECT *
		FROM VirginCombos
		UNION ALL
		SELECT *
		FROM VisaCombos
	), AllCombosCounts as (
		select brandid,narrative,locationCountry,MCCID, SUM(ComboCount) TotalComboCount
		from AllCombos
		group by  brandid,narrative,locationCountry,MCCID
	)
	select *
	into #AllCombosCounts
	from AllCombosCounts


	/**********************
	** General Audit
	**********************/

	IF (@BrandNameSearch = '' )
	BEGIN

	IF OBJECT_ID('tempdb..#NumberOfBrands') IS NOT NULL DROP TABLE #NumberOfBrands
	select narrative,locationCountry,MCCID, COUNT(DISTINCT Brandid) numberOfBrands
	into #NumberOfBrands
	from #AllCombosCounts
	group by  narrative,locationCountry,MCCID
	having COUNT(DISTINCT Brandid) > 1

	;With MoreThan1Brand as (
		select acc.*
		from #NumberOfBrands nob
		inner join #AllCombosCounts acc
		on acc.LocationCountry = nob.LocationCountry
		AND acc.MCCID = nob.MCCID
		AND acc.Narrative = nob.Narrative
		--ORDER BY acc.Narrative,acc.LocationCountry
	),totalDif as (
	select	b.BrandID Brand1
		,	b.Narrative Narrative1 
		,	b.TotalComboCount TotalComboCount1
		,	acc.BrandID Brand2
		,	acc.Narrative Narrative2
		,	acc.TotalComboCount TotalComboCount2
		,	CASE 
				WHEN b.TotalComboCount - acc.TotalComboCount < 0
					THEN RIGHT(b.TotalComboCount - acc.TotalComboCount, LEN(b.TotalComboCount - acc.TotalComboCount) - 1)
				ELSE b.TotalComboCount - acc.TotalComboCount
			END AS dif
	from MoreThan1Brand b
	join #AllCombosCounts acc
	on b.Narrative = acc.Narrative
	AND b.LocationCountry = acc.LocationCountry
	AND b.MCCID = acc.MCCID
	AND b.BrandID != acc.BrandID
	--ORDER BY b.TotalComboCount - acc.TotalComboCount desc
	)
	select *
	from totalDif
	order by dif desc

	END

	/**********************
	** Specified Brand Audit
	**********************/
	ELSE
	BEGIN

	IF OBJECT_ID('Sandbox.WilliamA.BrandAudit','U') IS NOT NULL DROP TABLE Sandbox.WilliamA.BrandAudit
	;With SpecifiedBrandCombos as (
		select *
		from #AllCombosCounts
		where BrandID IN (@BrandID)
	), NarrativeMatches as (
		select sbc.*,acc.BrandID as DifferentBrandID, acc.Narrative as SameNarrative, acc.TotalComboCount CountForDifferent,
		CASE 
				WHEN sbc.TotalComboCount - acc.TotalComboCount < 0
					THEN RIGHT(sbc.TotalComboCount - acc.TotalComboCount, LEN(sbc.TotalComboCount - acc.TotalComboCount) - 1)
				ELSE sbc.TotalComboCount - acc.TotalComboCount
			END AS dif,
		SOUNDEX(acc.Narrative) as brandedNarrative
		, SOUNDEX(sbc.Narrative) as otherNarrative
		from #AllCombosCounts acc
		join SpecifiedBrandCombos sbc
		on acc.Narrative = sbc.Narrative
		AND acc.LocationCountry = sbc.LocationCountry
		AND acc.MCCID = sbc.MCCID
		AND acc.BrandID != sbc.BrandID
	)
	select	ROW_NUMBER() OVER (PARTITION BY nm.BrandID order by dif desc) as idRow
		,	nm.BrandID
		,	b.BrandName
		,	nm.Narrative
		,	nm.LocationCountry
		,	nm.MCCID
		,	mcc.MCCGroup
		--,	nm.TotalComboCount
		--,	nm.DifferentBrandID AlternativeBrandID
		,	bb.brandName AlternativeBrandName
		--,	nm.CountForDifferent AlternativeComboCount
		--,	nm.dif DifferenceCounts
		,	(CAST(nm.dif AS FLOAT) / (CAST(nm.TotalComboCount AS FLOAT) + CAST(nm.CountForDifferent AS FLOAT))) ConfidenceRating
		,	CASE 
				WHEN nm.TotalComboCount >= nm.CountForDifferent
					THEN nm.BrandID
				else nm.DifferentBrandID
			END AS SuggestedBrandID
		,	CASE 
				WHEN nm.TotalComboCount >= nm.CountForDifferent
					THEN b.BrandName
				else bb.BrandName
			END AS SuggestedBrandName
	INTO Sandbox.WilliamA.BrandAudit
	from NarrativeMatches nm
	JOIN warehouse.Relational.Brand b
	on b.BrandID = nm.BrandID
	JOIN warehouse.Relational.Brand bb
	on bb.BrandID = nm.DifferentBrandID
	JOIN Warehouse.Relational.MCCList mcc
	ON mcc.MCCID = nm.MCCID
	--UNION 
	--select *
	--from soundexCompare
	order by dif desc

	END

