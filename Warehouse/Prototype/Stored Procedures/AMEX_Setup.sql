-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Description:	<Create the necessary architecture to run the rest of the AMEX data>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_Setup]
	(@SpecificBrand Int)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--						1. Determine Date Parameters
	-- Notes: 
	-- = We have set the data to align with AMEX results stream
	-- = AMEX Results Stream is ~ 6 weeks out of date
	-------------------------------------------------------------------------------------

	If @SpecificBrand IS NULL
		BEGIN
			If OBJECT_ID('Warehouse.Prototype.AMEX_Dates') IS NOT NULL TRUNCATE TABLE Warehouse.Prototype.AMEX_Dates		
		
			SET DATEFIRST 1

			INSERT INTO Warehouse.Prototype.AMEX_Dates
				SELECT	CAST(GETDATE() AS DATE) as RunDate
						 ,CASE WHEN DATEADD(DAY,-14,GETDATE()) < CAST(a.Data_To_This_Month AS DATE) THEN
							DATEADD(WEEK,-4,DATEADD(DAY,1,DATEADD(MONTH,-1,CAST(a.Data_To_This_Month AS DATE))))
						 ELSE
							DATEADD(WEEK,-4,DATEADD(DAY,1,CAST(a.Data_To_This_Month AS DATE)))
						 END AS StartDate
						,CASE WHEN DATEADD(DAY,-14,GETDATE()) < CAST(a.Data_To_This_Month AS DATE) THEN
							DATEADD(MONTH,-1,CAST(a.Data_To_This_Month AS DATE))
						 ELSE
							CAST(a.Data_To_This_Month AS DATE)
						 END AS EndDate
				FROM	(
							SELECT	CASE WHEN DATEPART(MONTH,GETDATE()) < 10 THEN
										CAST(DATEPART(YEAR,GETDATE()) as varchar(4)) + '-0' +  CAST(DATEPART(MONTH,GETDATE()) as varchar(2)) + '-' + '20'
									ELSE
										CAST(DATEPART(YEAR,GETDATE()) as varchar(4)) + '-' +  CAST(DATEPART(MONTH,GETDATE()) as varchar(2)) + '-' + '20'
									END Data_To_This_Month
						) a

		END

	SELECT @msg = 'Date specification complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--					2. Derive Brand List & Clean up tables 
	-------------------------------------------------------------------------------------

	TRUNCATE TABLE Warehouse.Prototype.AMEX_RefreshBrand
	TRUNCATE TABLE Warehouse.Prototype.AMEX_RunIssues

	If @SpecificBrand IS NULL
		BEGIN
			-- Clear ALL results from the table
			TRUNCATE TABLE Warehouse.Prototype.AMEX_BrandSegment
			TRUNCATE TABLE Warehouse.Prototype.AMEX_Seasonality
			TRUNCATE TABLE Warehouse.Prototype.AMEX_SpendStretch
			TRUNCATE TABLE Warehouse.Prototype.AMEX_SpenderAdj

			-- Select the brands currently live in the tool		 
			Insert Into Warehouse.Prototype.AMEX_RefreshBrand
				Select	BrandID
						,BrandName
						,ROW_NUMBER() over(order by BrandName) as RowNo
				From	Warehouse.Prototype.AMEX_BrandList

		END
	ELSE
		BEGIN
			-- Delete the brand from the brandlist if it exists
			DELETE FROM  Warehouse.Prototype.AMEX_BrandList WHERE BrandID = @SpecificBrand

			-- Add the brand to the AMEX BrandList
			Insert Into Warehouse.Prototype.AMEX_BrandList
				Select	BrandID
						,BrandName
				From	Warehouse.Relational.Brand 
				Where	BrandID = @SpecificBrand

			-- Clear SPECIFIC results from the table
			DELETE FROM  Warehouse.Prototype.AMEX_BrandSegment WHERE BrandID = @SpecificBrand
			DELETE FROM	 Warehouse.Prototype.AMEX_Seasonality WHERE BrandID = @SpecificBrand
			DELETE FROM  Warehouse.Prototype.AMEX_SpendStretch WHERE BrandID = @SpecificBrand
			DELETE FROM  Warehouse.Prototype.AMEX_SpenderAdj WHERE BrandID = @SpecificBrand

			--	Select the brand defined in the stored procedure
			Insert Into Warehouse.Prototype.AMEX_RefreshBrand
				Select	BrandID
						,BrandName
						,ROW_NUMBER() over(order by BrandName) as RowNo
				From	Warehouse.Prototype.AMEX_BrandList
				Where	BrandID = @SpecificBrand
		END

	DROP INDEX Prototype.AMEX_RefreshBrand.ix_Brand
	CREATE CLUSTERED INDEX ix_Brand on Warehouse.Prototype.AMEX_RefreshBrand(BrandID)

	SELECT @msg = 'Brand specification complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
END