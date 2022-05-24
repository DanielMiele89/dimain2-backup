-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <10/04/2017>
-- Description:	<Base Setup Script>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CumulGainsBase_v1]
	(
		@BrandList VARCHAR(600)
	)
AS
BEGIN
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--						1. Determine Date Parameters
	-- Notes: 
	-- = We look at last week for the last full month
	-- = Implication is that we should ideally run it AT LEAST ONE week into the month
	-------------------------------------------------------------------------------------

	If @BrandList IS NULL
		BEGIN
			If OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains') IS NOT NULL TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains		
		
			SET DATEFIRST 1

			INSERT INTO Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains
				SELECT	CAST(GETDATE() AS DATE) as RunDate
						-- Find the date 8 weeks prior to last full week of last month
						,case when DATEPART(dw,DATEADD(DAY,-(DAY(GETDATE())),GETDATE())) = 7 then
							CAST(DATEADD(DAY,-((DAY(GETDATE()))+55),GETDATE()) as Date) 
						 else
							CAST(DATEADD(DAY,-(DAY(GETDATE())+DATEPART(dw,DATEADD(DAY,-DAY(GETDATE()),GETDATE()))+55),GETDATE()) as Date)
						 end as StartEightWeek
						 -- Find the last full week of last month
						,case when DATEPART(dw,DATEADD(DAY,-(DAY(GETDATE())),GETDATE())) = 7 then
							CAST(DATEADD(DAY,-(DAY(GETDATE())),GETDATE()) as Date) 
						 else
							CAST(DATEADD(DAY,-(DAY(GETDATE())+DATEPART(dw,DATEADD(DAY,-DAY(GETDATE()),GETDATE()))),GETDATE()) as Date)
						 end as EndEightWeek	
		END

	SELECT @msg = 'Date specification complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--							2. Derive Brand List
	-------------------------------------------------------------------------------------

	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_RefreshBrand

	If @BrandList IS NULL
		BEGIN
			-- Clear ALL results from the table
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_DecayRates
			-- TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index

			-- Select the brands currently live in the tool		 
			Insert Into Warehouse.ExcelQuery.ROCEFT_RefreshBrand
				Select	BrandID
						,BrandName
						,ROW_NUMBER() over(order by BrandName) as RowNo
				From	Warehouse.ExcelQuery.ROCEFT_BrandList
		END
	ELSE
		BEGIN
			-- Clear SPECIFIC results from the table
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0	
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_DecayRates WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0	
			
			--	Select the brand defined in the stored procedure
			Insert Into Warehouse.ExcelQuery.ROCEFT_RefreshBrand
				Select	BrandID
						,BrandName
						,ROW_NUMBER() over(order by BrandName) as RowNo
				From	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	IF EXISTS(SELECT * FROM sys.indexes WHERE name = 'ix_Brand' and OBJECT_ID = OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_RefreshBrand'))
		BEGIN
			DROP INDEX ExcelQuery.ROCEFT_RefreshBrand.ix_Brand
		END
	CREATE CLUSTERED INDEX ix_Brand on Warehouse.ExcelQuery.ROCEFT_RefreshBrand(BrandID)

	SELECT @msg = 'Brand specification complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--					3. Specify how to treat each Publisher
	-- Notes:
	-- = This is dealt in the ROC script
	-- = If Random is changed to Ranked, it will start applying the same algorithm
	--   as is applied to JUST Quidco otherwise
	-------------------------------------------------------------------------------------

	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Publishers

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_Publishers
		Values
			(144,'Airtime Rewards','Random')
			,(148,'Collinson - Avios','Random')
			,(149,'Collinson - BAA','Random')
			,(147,'Collinson - Virgin','Random')
			,(156,'Collinson - UA','Random')
			,(155,'Gobsmack - More Than','Random')
			,(157,'Gobsmack - Mustard','Random')
			,(12,'Quidco','Ranked')
			,(145,'Next Jump','Random')
			,(NULL,'RBS','Other')
			,(NULL,'Top Cashback','Random')
			,(NULL,'Complete Savings','Random')
			,(NULL,'HSBC Advance','Random')
			,(158,'Gobsmack - Admiral','Random')
			,(NULL,'Gobsmack - Thomas Cook','Random')
			,(NULL,'Gobsmack - Ageas','Random')
			,(167,'Monzo','Random')
			,(166,'Virgin Money VGLC','Random')
			,(168,'Endsleigh Insurance','Random')

	SELECT @msg = 'Brand specification complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

END

