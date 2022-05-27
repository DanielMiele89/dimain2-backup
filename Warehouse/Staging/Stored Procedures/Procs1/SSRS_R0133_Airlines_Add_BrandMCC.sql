


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 17/10/2016
-- Description: Add Brand&MCC to Table
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0133_Airlines_Add_BrandMCC](
			@BID smallint, @M int)
									
AS

	SET NOCOUNT ON;

/************************************************************
*********** ADD respective BrandID & MCC to table ***********
************************************************************/
declare @BrandID int,
		@Brandname varchar(50),
		@MCC int,
		@MCCDesc varchar(200)

SET @BrandID =		@BID
SET	@Brandname =	(SELECT Brandname from warehouse.Relational.Brand where BrandID = @BrandID)
SET @MCC =			@M
SET @MCCDesc =		(SELECT MCCDesc from Warehouse.Relational.MCCList where MCC = @MCC)

insert into Warehouse.Staging.R_0133_IncludedMCCs
(BrandID, BrandName, MCC, MCCDesc)
values
(@BrandID, @Brandname, @MCC,@MCCDesc)

select *
from Warehouse.Staging.R_0133_IncludedMCCs
where BrandID = @BrandID