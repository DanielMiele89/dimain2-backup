CREATE TABLE [MI].[RetailReportBrand] (
    [PartnerID]   INT          NOT NULL,
    [BrandID]     SMALLINT     NOT NULL,
    [PartnerName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_RetailerReportBrand] PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

