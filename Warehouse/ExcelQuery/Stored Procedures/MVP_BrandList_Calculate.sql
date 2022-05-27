-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <8th June 2018>
-- Description:	<Brand List to manage when brands are added, and remove them from downstream tables when things change>
-- =============================================
CREATE PROCEDURE ExcelQuery.[MVP_BrandList_Calculate]
	@BrandList VARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	/*
	-- Create table statement

	IF OBJECT_ID('Warehouse.Prototype.MVP_BrandList') IS NOT NULL DROP TABLE Warehouse.Prototype.MVP_BrandList
	CREATE TABLE Warehouse.Prototype.MVP_BrandList
		(
			ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
			BrandID INT NOT NULL,
			BrandName VARCHAR(50) NOT NULL,
			AcquireLength INT NOT NULL,
			LapsedLength INT NOT NULL,
			Override FLOAT,
			IsPartner BIT NOT NULL,
			StartDate DATE NOT NULL,
			EndDate DATE NULL
		)

	CREATE NONCLUSTERED INDEX cix_BrandID on Warehouse.Prototype.MVP_BrandList (BrandID) INCLUDE (EndDate)
	*/

	-- TEST
	-- DECLARE @BrandList VARCHAR(500) = '12,485'

	-- Find Brands
	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
	(
		BrandID INT NOT NULL PRIMARY KEY
		,BrandName VARCHAR(50)
		,RowNo INT
	)

	INSERT INTO #Brand
		SELECT	BrandID
				,BrandName
				,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

	DECLARE @i INT = 1
	DECLARE @BrandID INT
	DECLARE @BrandName VARCHAR(50)

	WHILE @i <= (SELECT MAX(RowNo) FROM #Brand)
		BEGIN
		
			SELECT @BrandID = BrandID FROM #Brand WHERE RowNo = @i

			-- Find the Brand Details Required to Insert
			IF OBJECT_ID('tempdb..#Insert') IS NOT NULL DROP TABLE #Insert
			SELECT		a.BrandID,
						a.BrandName,
						als.AcquireL as AcquireLength,
						als.LapserL as LapsedLength,
						CASE WHEN c.Override_Pct_of_CBP IS NULL THEN 0 ELSE c.Override_Pct_of_CBP END AS Override,
						CASE WHEN p.BrandID IS NULL THEN 0 ELSE 1 END AS IsPartner
			INTO		#Insert
			FROM		#Brand a
			LEFT JOIN	Warehouse.Relational.partner b on a.BrandID = b.BrandID
			LEFT JOIN	Warehouse.Relational.Master_Retailer_Table c on c.PartnerID = b.PartnerID
			LEFT JOIN	(	SELECT  DISTINCT BrandID
							FROM   Warehouse.Relational.Partner
							WHERE BrandID IS NOT NULL
							UNION
							SELECT  DISTINCT br.BrandID
							FROM	nFI.Relational.Partner p
							JOIN	Warehouse.Staging.Partners_Vs_Brands pvb
								ON	p.PartnerID = pvb.PartnerID
							JOIN    Warehouse.Relational.Brand      br
								ON  pvb.BrandID = br.BrandID
						) p
						ON	a.BrandID = p.BrandID
			LEFT JOIN	(	SELECT	DISTINCT
									br.BrandID
									,COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
									,COALESCE(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
									,br.SectorID
							FROM	(
										SELECT	DISTINCT BrandID
												,BrandName
												,SectorID
												,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 3 END AS AcquireL0
												,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 1 END AS LapserL0
										FROM	Warehouse.Relational.Brand
									) br
							LEFT JOIN	Warehouse.Relational.Partner p on p.BrandID = br.BrandID
							LEFT JOIN	Warehouse.Relational.MRF_ShopperSegmentDetails mrf on mrf.PartnerID = p.PartnerID
							LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on br.BrandID = blk.BrandID
							LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on br.SectorID = lk.SectorID
						) als
						ON	a.BrandID = als.brandID
			WHERE		a.RowNo = @i

			-- Check whether this Combo already exists in the table
			DECLARE @ComboExists INT = (
											SELECT	COUNT(*)
											FROM	Warehouse.ExcelQuery.MVP_BrandList bl
											WHERE	EXISTS
												(	SELECT	1
													FROM	#Insert i
													WHERE	bl.BrandID = i.BrandID
														AND	bl.BrandName = i.BrandName
														AND bl.AcquireLength = i.AcquireLength
														AND bl.LapsedLength = i.LapsedLength
														AND	bl.Override = i.Override
														AND bl.IsPartner = i.IsPartner )
										)

			-- Check whether this brand already exists in the table, but combo does not
			DECLARE @BrandExists INT = (
											SELECT	COUNT(*)
											FROM	Warehouse.ExcelQuery.MVP_BrandList bl
											WHERE	EXISTS
												(	SELECT	1
													FROM	#Insert i
													WHERE	bl.BrandID = i.BrandID
														AND	bl.BrandName = i.BrandName
														AND	
														(
															bl.AcquireLength != i.AcquireLength
														OR	bl.LapsedLength != i.LapsedLength
														OR	bl.Override != i.Override
														OR	bl.IsPartner != i.IsPartner
														)
												)
										)

			IF @ComboExists = 0 
				BEGIN
					IF @BrandExists != 0 
						BEGIN
						-- If the combo does not exist, but the brand does, close off the old record, add a new one and delete the brand from all the current tables

							-- Close off old record
							UPDATE bl
							SET	EndDate = DATEADD(DAY,-1,GETDATE())
							FROM Warehouse.ExcelQuery.MVP_BrandList bl
							WHERE	EXISTS
								(	SELECT	1
									FROM	#Insert i
									WHERE	bl.BrandID = i.BrandID
										AND	bl.BrandName = i.BrandName )
								AND EndDate IS NULL
								
							-- Create new record
							INSERT INTO	Warehouse.ExcelQuery.MVP_BrandList
								SELECT	BrandID,
										BrandName,
										AcquireLength,
										LapsedLength,
										Override,
										IsPartner,
										CAST(GETDATE() AS DATE) AS StartDate,
										NULL AS EndDate
								FROM	#Insert

							-- Delete brand from other tables
							-- DELETE FROM Warehouse.Prototype.MVP_InProgramme_NaturalSalesByCycle WHERE BrandID = @BrandID
							-- DELETE FROM Warehouse.Prototype.MVP_InProgramme_SpendStretch WHERE BrandID = @BrandID
							-- DELETE FROM Warehouse.Prototype.MVP_OutOfProgramme_NaturalSalesByCycle WHERE BrandID = @BrandID
							-- DELETE FROM Warehouse.Prototype.MVP_OutOfProgramme_SpendStretch WHERE BrandID = @BrandID
						END
					ELSE
						BEGIN
						-- If the combo does not exist and the brand does not exist just add it to the table

							INSERT INTO	Warehouse.ExcelQuery.MVP_BrandList
								SELECT	BrandID,
										BrandName,
										AcquireLength,
										LapsedLength,
										Override,
										IsPartner,
										CAST(GETDATE() AS DATE) AS StartDate,
										NULL AS EndDate
								FROM	#Insert
						END
				END

			-- Iterate Loop
			SET @i = @i +1
		END

END
