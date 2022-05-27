CREATE TABLE [Staging].[R_0060_Outlet_NotinMIDS] (
    [ConsumerCombinationID] INT             NOT NULL,
    [MerchantID]            VARCHAR (50)    NULL,
    [Narrative]             VARCHAR (50)    NULL,
    [LocationCountry]       VARCHAR (3)     NULL,
    [MCC]                   VARCHAR (4)     NULL,
    [MCCDesc]               VARCHAR (200)   NULL,
    [FirstTran]             DATE            NULL,
    [LastTran]              DATE            NULL,
    [Trans]                 INT             NULL,
    [Offline Tranx]         INT             NULL,
    [Offline Cashback]      NUMERIC (38, 2) NULL,
    [Online Tranx]          INT             NULL,
    [Online Cashback]       NUMERIC (38, 2) NULL,
    [PartnerID]             INT             NULL
);

