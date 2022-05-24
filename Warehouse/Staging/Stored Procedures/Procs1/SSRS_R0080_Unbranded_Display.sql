/*
		Author:			Ijaz Amjad

		Date:			07-04-2016

		Purpose:		To display data for the report

*/
CREATE Procedure [Staging].[SSRS_R0080_Unbranded_Display] (@Rows int)
As

Declare @Row int

Set @Row = @Rows

Select Top (@Row) *
From [Staging].[R_0080_Unbranded_BrandSuggestionsV3]
Order by [TransactionAmount_LastYear] Desc
