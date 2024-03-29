﻿CREATE TABLE [InsightArchive].[MyRewards_ControlGroup_InProgram] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (10) NOT NULL,
    [IronOfferID]          INT          NOT NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [ShopperSegment]       VARCHAR (15) NOT NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [FanID]                INT          NOT NULL,
    [PercentageTaken]      INT          NOT NULL,
    [ExcludeFromAnalysis]  BIT          NOT NULL,
    CONSTRAINT [PK_MyRewards_ControlGroup_InProgram] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX1_MyRewards_ControlGroup_InProgram]
    ON [InsightArchive].[MyRewards_ControlGroup_InProgram]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [NCIX2_MyRewards_ControlGroup_InProgram]
    ON [InsightArchive].[MyRewards_ControlGroup_InProgram]([IronOfferID] ASC)
    INCLUDE([FanID]);

