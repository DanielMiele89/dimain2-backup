CREATE TABLE [Report].[OfferReport_ConsumerCombinations_InProgramme] (
    [DataSource]            VARCHAR (15) NULL,
    [ConsumerCombinationID] INT          NULL,
    [RetailerID]            INT          NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_PartnerID]
    ON [Report].[OfferReport_ConsumerCombinations_InProgramme]([RetailerID] ASC);

