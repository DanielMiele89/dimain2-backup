-- =============================================
-- Author:		Rory Francis
-- Create date: 2020-02-19
-- Description:	Retrieves BrandSpend information for AWS File
-- =============================================
CREATE PROCEDURE [AWSFile].[BrandSpend_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ID
		 , FilterID
		 , IsRewardPartner
		 , BrandID
		 , BrandName
		 , SectorID
		 , SectorName
		 , SectorGroupID
		 , SectorGroupName
		 , TransactionChannel
		 , CustomerType
		 , TransactionType
		 , Amount
		 , AmountOnline
		 , Transactions
		 , Customers
		 , CustomersPerSector
		 , CustomersPerSectorGroup
		 , TotalCustomers
		 , AmountLastYear
		 , AmountOnlineLastYear
		 , TransactionsLastYear
		 , CustomersLastYear
		 , CustomersPerSectorLastYear
		 , CustomersPerSectorGroupLastYear
		 , LastAudited
	FROM [MI].[TotalBrandSpend_RBSG_V2]
    
END