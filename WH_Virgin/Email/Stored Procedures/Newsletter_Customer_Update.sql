/*

	Author:		Stuart Barnley

	Date:		21th July 2017

	Purpose:	Populate Customer Random number table, this is used by OPE process to 
				deal with conflicts

*/

CREATE PROCEDURE [Email].[Newsletter_Customer_Update]
AS
BEGIN

	DECLARE @RowNo INT

	/*--------------------------------------------------------------------------------------------------
	------------------------------Empty Table in Preparation for new data-------------------------------
	----------------------------------------------------------------------------------------------------*/

		TRUNCATE TABLE [Email].[Newsletter_Customer]

		INSERT INTO [Email].[Newsletter_Customer] (	[Email].[Newsletter_Customer].[FanID]
												,	[Email].[Newsletter_Customer].[CompositeID]
												,	[Email].[Newsletter_Customer].[RandomNumber])
		SELECT [Derived].[Customer].[FanID]
			 , [Derived].[Customer].[CompositeID]
			 , ABS(CHECKSUM(NEWID())) AS RandomNumber
		FROM [Derived].[Customer]
		WHERE [Derived].[Customer].[MarketableByEmail] = 1
		AND [Derived].[Customer].[CurrentlyActive] = 1

		ALTER INDEX CIX_RandomComp ON [Email].[Newsletter_Customer] REBUILD WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)



END