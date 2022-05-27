CREATE TABLE [InsightArchive].[EnterpriseMIDsToReprocess20191119] (
    [PartnerID]         INT           NOT NULL,
    [RetailOutletID]    INT           IDENTITY (1, 1) NOT NULL,
    [MerchantID]        NVARCHAR (50) NOT NULL,
    [ReprocessFromDate] VARCHAR (10)  NOT NULL
);

