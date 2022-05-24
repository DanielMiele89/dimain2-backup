CREATE TABLE [Staging].[R_0136_RetailerOutletTracking] (
    [Year]                  INT           NULL,
    [Month]                 VARCHAR (50)  NULL,
    [PartnerID]             INT           NULL,
    [PartnerName]           VARCHAR (100) NULL,
    [Amount_nFI]            MONEY         NULL,
    [Outlets_nFI]           INT           NULL,
    [OutletsDifference_nFI] INT           NULL,
    [Amount_RBS]            MONEY         NULL,
    [Outlets_RBS]           INT           NULL,
    [OutletsDifference_RBS] INT           NULL
);

