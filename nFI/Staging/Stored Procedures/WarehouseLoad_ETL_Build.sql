
-- ******************************************************************
-- Author: Suraj Chahal
-- Create date: 02/02/2016
-- Description: Build ETL for all nFIs on the Relational.Club table
-- ******************************************************************

/************************Change History****************************
05/02/2016 - SC - Added Staging.WarehouseLoad_Customer_PaymentCard
03/03/2016 - SB - Changed to make sure Offer table is populated and
				  IronOffer table is updated accordingly
02/02/2017 - SB - Changes made to accommodate changes to IOM table
******************************************************************/

CREATE PROCEDURE [Staging].[WarehouseLoad_ETL_Build]
		
AS
BEGIN
	SET NOCOUNT ON;

/********************************************
*********Write entry to JobLog Table*********
********************************************/
INSERT INTO Staging.JobLog
SELECT	StoredProcedureName = 'ETL_Build_Start',
		TableSchemaName = '',
		TableName = '',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = NULL


--**SPs
EXEC Staging.WarehouseLoad_Customer
EXEC Staging.WarehouseLoad_Customer_PaymentCardV1_1
EXEC Staging.WarehouseLoad_IronOffer_v1_1
EXEC Staging.WarehouseLoad_AddOfferIDs_to_Ironoffer
EXEC Staging.WarehouseLoad_IronOffer_PartnerCommissionRule
--EXEC Staging.WarehouseLoad_IronOfferMember
EXEC Staging.WarehouseLoad_IronOfferMember_V1_2 -- 02/02/2017 - SB


EXEC Staging.WarehouseLoad_Partner
EXEC Staging.WarehouseLoad_Outlet
--EXEC Staging.WarehouseLoad_PartnerTrans
EXEC [Staging].[WarehouseLoad_PartnerTrans_V2]	--	02-07-2020	-	RF
EXEC Staging.WarehouseLoad_PrimaryRetailerIdentification

IF DATENAME(DW,GETDATE()) in ('Sunday')
	BEGIN 
		Exec Staging.WarehouseLoad_IronOfferMemberUpdate
	END

/********************************************
*********Write entry to JobLog Table*********
********************************************/
INSERT INTO Staging.JobLog
SELECT	StoredProcedureName = 'ETL_Build_End',
	TableSchemaName = '',
	TableName = '',
	StartDate = GETDATE(),
	EndDate = GETDATE(),
	TableRowCount  = NULL,
	AppendReload = NULL

END

