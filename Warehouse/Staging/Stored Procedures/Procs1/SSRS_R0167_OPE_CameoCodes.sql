/*

	Author:			Stuart Barnley

	Date:			25th July 2017

	Purpose:		To display a list of the Cameo Code Groups are

*/

Create Procedure staging.SSRS_R0167_OPE_CameoCodes
With Execute as Owner
As

Select	CAMEO_CODE_GROUP,
		Social_Class,
		CAMEO_CODE_GROUP_Category
From warehouse.[Relational].[CAMEO_CODE_GROUP]