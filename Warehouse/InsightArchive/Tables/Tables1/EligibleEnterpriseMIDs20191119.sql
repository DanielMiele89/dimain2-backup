CREATE TABLE [InsightArchive].[EligibleEnterpriseMIDs20191119] (
    [RetailOutletID]          INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]               INT           NOT NULL,
    [MerchantID]              NVARCHAR (50) NOT NULL,
    [FanID]                   INT           NOT NULL,
    [SuppressFromSearch]      BIT           NOT NULL,
    [Channel]                 TINYINT       NOT NULL,
    [PartnerOutletReference]  NVARCHAR (20) NULL,
    [GeolocationUpdateFailed] BIT           NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_ID]
    ON [InsightArchive].[EligibleEnterpriseMIDs20191119]([RetailOutletID] ASC);

