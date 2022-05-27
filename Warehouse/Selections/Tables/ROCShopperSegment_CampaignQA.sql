CREATE TABLE [Selections].[ROCShopperSegment_CampaignQA] (
    [PartnerID]         INT           NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    [ClientServicesRef] VARCHAR (255) NULL,
    [BriefFolder]       VARCHAR (255) NULL,
    [BriefFileName]     VARCHAR (255) NULL,
    [BriefFilePath]     AS            (([BriefFolder]+[BriefFileName])+'.xlsx')
);

