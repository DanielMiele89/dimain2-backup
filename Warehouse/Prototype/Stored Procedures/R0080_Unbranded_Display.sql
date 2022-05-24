/*
		Author:			Stuart Barnley

		Date:			30-03-2016

		Purpose:		To display data for the report

*/
CREATE Procedure Prototype.R0080_Unbranded_Display (@Rows int)
As

Declare @Row int

Set @Row = @Rows

Select Top (@Row) *
From [Prototype].[SSRS_R0080_Unbranded_BrandSuggestions]
Order by [ATV_LastYear] Desc
