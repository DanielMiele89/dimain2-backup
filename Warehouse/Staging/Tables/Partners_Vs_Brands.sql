CREATE TABLE [Staging].[Partners_Vs_Brands] (
    [PartnerID] INT      NULL,
    [BrandID]   SMALLINT NULL
);


GO
CREATE CLUSTERED INDEX [cix_Partners_Vs_Brands_PartnerID]
    ON [Staging].[Partners_Vs_Brands]([PartnerID] ASC);

