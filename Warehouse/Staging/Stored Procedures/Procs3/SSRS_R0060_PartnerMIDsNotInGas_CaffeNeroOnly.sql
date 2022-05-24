--Use Warehouse
/*
	Author:		Stuart Barnley

	Date:		03rd June 2016

	Purpose:	This stored procedure is used to populate the report with just those MIDs related to Caffé Nero

*/


Create Procedure Staging.SSRS_R0060_PartnerMIDsNotInGas_CaffeNeroOnly

As

Truncate Table Staging.R_0060_Outlet_NotinMIDS --- Empty the Table

Exec [Staging].[SSRS_R0060_PartnerMIDsNotInGAS_PerPartner] 4319 --- Run the assessment for Caffé Nero only