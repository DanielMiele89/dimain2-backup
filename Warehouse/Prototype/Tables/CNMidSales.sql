CREATE TABLE [Prototype].[CNMidSales] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [Scheme]      NVARCHAR (10)  NULL,
    [StartDate]   DATE           NULL,
    [EndDate]     DATE           NULL,
    [MerchantID]  NVARCHAR (50)  NULL,
    [FullAddress] NVARCHAR (200) NULL,
    [Total]       SMALLMONEY     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

